import eventlet
eventlet.monkey_patch()

import gc
import sqlite3
import shutil
import base64
import cv2
import numpy as np
import os
import re
import json
import binascii
import csv
import io
import tempfile
import secrets
import smtplib
from email.message import EmailMessage
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request as UrlRequest, urlopen
from datetime import datetime, timedelta
from pathlib import Path
from dotenv import load_dotenv
from flask import Flask, render_template, request, session, redirect, url_for, jsonify, abort, send_file, make_response
from flask_socketio import SocketIO, emit
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from PIL import Image, ImageDraw, ImageFont
from question_bank import (
    QUESTION_BANKS,
    build_exam_for_student,
    build_exam_from_paper,
    grade_exam_submission,
    grade_exam_submission_from_paper,
)

load_dotenv(Path(__file__).resolve().parent / ".env", override=True)

app = Flask(__name__)
configured_secret = os.environ.get("SECRET_KEY")
app.secret_key = configured_secret or secrets.token_urlsafe(32)
if not configured_secret:
    app.logger.warning("SECRET_KEY is not set; generated a temporary local session secret.")
app.config.update(
    MAX_CONTENT_LENGTH=8 * 1024 * 1024,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    SESSION_COOKIE_SECURE=os.environ.get("SESSION_COOKIE_SECURE", "").strip().lower() in {"1", "true", "yes", "on"},
)
socketio = SocketIO(app, cors_allowed_origins=os.environ.get("SOCKETIO_CORS_ORIGINS"), async_mode='eventlet')

# --- CONFIGURATION ---
BASE_DIR = Path(__file__).resolve().parent
BUNDLED_DB_PATH = BASE_DIR / "proctor_system.db"
DB_RUNTIME_DIR = Path(os.environ.get("PROCTOR_DB_DIR") or (Path(tempfile.gettempdir()) / "proctoring_project"))
DB_RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
DB_NAME = os.environ.get("PROCTOR_DB_PATH", str(DB_RUNTIME_DIR / "proctor_system.db"))
UPLOAD_FOLDER = 'static/profiles'
VIOLATION_PROOF_FOLDER = 'static/violation_proofs'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
FORBIDDEN_OBJECTS = ['cell phone', 'mobile phone', 'laptop', 'book', 'tablet']
YOLO_MODEL = None 
YOLO_MODEL_FAILED_AT = None
FACE_CASCADE = None
ACTIVE_EXAMS = {}
ADMIN_SIDS = set()
STUDENT_SIDS = {}
ADMIN_USERNAME = os.environ.get("ADMIN_USERNAME", "ADMIN")
ADMIN_INITIAL_PASSWORD = os.environ.get("ADMIN_INITIAL_PASSWORD")
GOOGLE_CLIENT_ID = os.environ.get("GOOGLE_CLIENT_ID", "").strip()
GOOGLE_CLIENT_SECRET = os.environ.get("GOOGLE_CLIENT_SECRET", "").strip()
GOOGLE_REDIRECT_URI = os.environ.get("GOOGLE_REDIRECT_URI", "").strip()
SMTP_HOST = os.environ.get("SMTP_HOST", "").strip()
SMTP_PORT = int(os.environ.get("SMTP_PORT", "587"))
SMTP_USERNAME = os.environ.get("SMTP_USERNAME", "").strip()
SMTP_PASSWORD = os.environ.get("SMTP_PASSWORD", "")
MAIL_FROM = os.environ.get("MAIL_FROM", SMTP_USERNAME).strip()
RUN_HOST = os.environ.get("HOST", "0.0.0.0")
RUN_PORT = int(os.environ.get("PORT", "5000"))
RUN_DEBUG = os.environ.get("FLASK_DEBUG", "").strip().lower() in {"1", "true", "yes", "on"}
# Small objects such as phones disappear at 320px, especially on mobile-camera frames.
DETECTION_FRAME_WIDTH = max(480, int(os.environ.get("DETECTION_FRAME_WIDTH", "512")))
MODEL_LOAD_RETRY_SECONDS = max(10, int(os.environ.get("MODEL_LOAD_RETRY_SECONDS", "60")))
VIOLATION_AUTO_SUBMIT_SCORE = 20
SECTION_ORDER = ["section_a", "section_b", "section_c"]
SECTION_LABELS = {
    "section_a": "Section A",
    "section_b": "Section B",
    "section_c": "Section C"
}
SECTION_TYPES = {
    "section_a": "mcq",
    "section_b": "true_false",
    "section_c": "fill_blank"
}
DEFAULT_SECTION_MARKS = {
    "section_a": 2,
    "section_b": 2,
    "section_c": 1
}
SUGGESTION_LIBRARY = {
    "section_a": "Weak in Section A. Revise key definitions and practice short concept-based MCQs.",
    "section_b": "Weak in Section B. Focus on true/false reasoning and review one-line theory facts.",
    "section_c": "Weak in Section C. Practice recall-based questions and write concise fill-in answers.",
}


def prepare_database_file():
    runtime_path = Path(DB_NAME)
    runtime_path.parent.mkdir(parents=True, exist_ok=True)
    if runtime_path.exists():
        return
    if BUNDLED_DB_PATH.exists():
        shutil.copy2(BUNDLED_DB_PATH, runtime_path)
    else:
        runtime_path.touch()

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['VIOLATION_PROOF_FOLDER'] = VIOLATION_PROOF_FOLDER
if not os.path.exists(VIOLATION_PROOF_FOLDER):
    os.makedirs(VIOLATION_PROOF_FOLDER)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def is_valid_profile_image(uploaded_file):
    try:
        uploaded_file.stream.seek(0)
        with Image.open(uploaded_file.stream) as image:
            image.verify()
        uploaded_file.stream.seek(0)
        return True
    except Exception:
        uploaded_file.stream.seek(0)
        return False


def normalize_email_address(value):
    email = str(value or "").strip().lower()
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email) or len(email) > 254:
        return None
    return email


def selected_recovery_methods(value):
    return {method for method in str(value or "").split(",") if method in {"phone", "email"}}


def send_password_reset_otp(recipient, code):
    if not all((SMTP_HOST, SMTP_USERNAME, SMTP_PASSWORD, MAIL_FROM)):
        raise RuntimeError("Email OTP is not configured yet. Add SMTP settings to your local .env file.")

    message = EmailMessage()
    message["Subject"] = "Your ProctorX password reset code"
    message["From"] = MAIL_FROM
    message["To"] = recipient
    message.set_content(
        f"Your ProctorX password reset code is: {code}\n\n"
        "This code expires in 10 minutes. If you did not request it, you can ignore this email."
    )
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15) as smtp:
        smtp.starttls()
        smtp.login(SMTP_USERNAME, SMTP_PASSWORD)
        smtp.send_message(message)


def get_socket_student_id():
    if session.get("role") != "student":
        return None
    return session.get("user_id")


def google_oauth_enabled():
    return bool(GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET)


def get_google_redirect_uri():
    return GOOGLE_REDIRECT_URI or url_for("google_callback", _external=True)


def exchange_google_code(code, redirect_uri):
    payload = urlencode({
        "code": code,
        "client_id": GOOGLE_CLIENT_ID,
        "client_secret": GOOGLE_CLIENT_SECRET,
        "redirect_uri": redirect_uri,
        "grant_type": "authorization_code",
    }).encode("utf-8")
    token_request = UrlRequest(
        "https://oauth2.googleapis.com/token",
        data=payload,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urlopen(token_request, timeout=12) as response:
        return json.loads(response.read().decode("utf-8"))


def verify_google_identity(id_token_value):
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token

    identity = id_token.verify_oauth2_token(
        id_token_value,
        google_requests.Request(),
        GOOGLE_CLIENT_ID,
    )
    if not identity.get("sub") or not identity.get("email") or not identity.get("email_verified"):
        raise ValueError("Google did not return a verified email address.")
    return identity


def normalize_student_identifier(student_id):
    safe_student_id = secure_filename(str(student_id or "unknown"))
    return safe_student_id or "unknown"


def save_violation_evidence(student_id, data_url, label="violation"):
    if not data_url or "," not in str(data_url):
        return None

    try:
        header, encoded = data_url.split(",", 1)
    except ValueError:
        return None

    extension = "jpg"
    if "image/png" in header:
        extension = "png"
    elif "image/webp" in header:
        extension = "webp"

    safe_student_id = normalize_student_identifier(student_id)
    safe_label = secure_filename(label) or "violation"
    filename = f"{safe_student_id}_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}_{safe_label}.{extension}"
    output_path = os.path.join(app.config['VIOLATION_PROOF_FOLDER'], filename)

    try:
        with open(output_path, "wb") as file_obj:
            file_obj.write(base64.b64decode(encoded))
    except (binascii.Error, ValueError, OSError):
        return None

    return f"violation_proofs/{filename}"


def remove_violation_proof(relative_path):
    if not relative_path:
        return

    normalized_path = os.path.normpath(relative_path).replace("\\", "/")
    if not normalized_path.startswith("violation_proofs/"):
        return

    absolute_path = os.path.normpath(os.path.join("static", normalized_path.replace("/", os.sep)))
    if os.path.exists(absolute_path):
        try:
            os.remove(absolute_path)
        except OSError:
            pass


def get_recent_violation_count(student_id, match_terms, within_seconds=None):
    if isinstance(match_terms, str):
        match_terms = [match_terms]
    rows = []
    with get_db_connection() as conn:
        rows = conn.execute(
            "SELECT type, created_at FROM violations WHERE student_id=? ORDER BY id DESC",
            (student_id,)
        ).fetchall()

    now = datetime.now()
    count = 0
    for row in rows:
        violation_text = str(row["type"] or "").lower()
        if not any(term.lower() in violation_text for term in match_terms):
            continue
        if within_seconds:
            timestamp = parse_timestamp(row["created_at"])
            if not timestamp or (now - timestamp).total_seconds() > within_seconds:
                continue
        count += 1
    return count


def classify_violation(violation_type, student_id=None):
    violation_text = str(violation_type or "").lower()
    score = 0
    matched_rules = []

    if "no face detected > 5 seconds" in violation_text or "no face detected for > 5 sec" in violation_text:
        score += 2
        matched_rules.append("face_absent")
    elif "no face detected" in violation_text:
        score += 2
        matched_rules.append("face_absent")

    if "looking away" in violation_text:
        score += 1
        matched_rules.append("looking_away")

    if "multiple people" in violation_text or "multiple faces" in violation_text:
        score += 5
        matched_rules.append("multiple_faces")

    if "tab switch" in violation_text or "window minimized" in violation_text:
        prior_switches = get_recent_violation_count(student_id, ["tab switch", "window minimized"], None) if student_id else 0
        if prior_switches >= 1:
            score += 3
            matched_rules.append("additional_switch")
        if student_id and get_recent_violation_count(student_id, ["tab switch", "window minimized"], 60) >= 2:
            score += 3
            matched_rules.append("rapid_switching")

    if "loud noise" in violation_text or "background noise" in violation_text:
        score += 1
        matched_rules.append("background_noise")

    if "talking detected" in violation_text or "talking" in violation_text:
        score += 2
        matched_rules.append("talking")

    if "multiple voices" in violation_text:
        score += 4
        matched_rules.append("multiple_voices")

    if "cell phone" in violation_text or "mobile phone" in violation_text or "phone detected" in violation_text or "detected: cell phone" in violation_text:
        score += 5
        matched_rules.append("phone")

    if "detected: book" in violation_text or "notes detected" in violation_text:
        score += 4
        matched_rules.append("notes")

    if "restricted action: copy" in violation_text or "restricted action: paste" in violation_text or "copy/paste attempt" in violation_text:
        score += 5
        matched_rules.append("copy_paste")

    if "inactivity (afk) > 2 minutes" in violation_text or "afk" in violation_text:
        score += 2
        matched_rules.append("afk")

    if score >= 5:
        severity = "high"
    elif score >= 2:
        severity = "medium"
    else:
        severity = "low"

    return severity, score, matched_rules


def create_violation_record(student_id, violation_type, evidence_image=None):
    current = ACTIVE_EXAMS.get(student_id, {})
    evidence_path = save_violation_evidence(student_id, evidence_image, violation_type)
    severity, score, matched_rules = classify_violation(violation_type, student_id)
    created_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with get_db_connection() as conn:
        conn.execute(
            """
            INSERT INTO violations (student_id, type, timestamp, evidence_path, severity, score, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                student_id,
                violation_type,
                datetime.now().strftime("%H:%M:%S"),
                evidence_path,
                severity,
                score,
                created_at
            )
        )
        conn.commit()
    current_count = int(current.get("violation_count", 0)) + 1
    exam_started_at = current.get("exam_started_at")
    since_time = parse_timestamp(exam_started_at) if exam_started_at else datetime.now() - timedelta(hours=2)
    risk_score, risk_level = compute_risk_for_student(student_id, since_time)
    violation_total = int(current.get("violation_score_total", 0) or 0) + int(score or 0)
    refresh_live_exam(
        student_id,
        violation_count=current_count,
        violation_score_total=violation_total,
        risk_score=risk_score,
        risk_level=risk_level,
        latest_violation=violation_type,
        current_frame=evidence_path
    )
    if severity == "high" or ("tab switch" in str(violation_type).lower() and current_count >= 3):
        create_notification(student_id, violation_type, severity, {"evidence_path": evidence_path})
    return {
        "message": violation_type,
        "score": int(score or 0),
        "total_score": violation_total,
        "risk_score": risk_score,
        "risk_level": risk_level,
        "severity": severity,
        "matched_rules": matched_rules,
        "auto_submit": violation_total > VIOLATION_AUTO_SUBMIT_SCORE,
        "threshold": VIOLATION_AUTO_SUBMIT_SCORE,
    }


def ensure_column_exists(cursor, table_name, column_name, column_definition):
    columns = [row[1] for row in cursor.execute(f"PRAGMA table_info({table_name})").fetchall()]
    if column_name not in columns:
        cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN {column_definition}")


def get_db_connection():
    conn = sqlite3.connect(DB_NAME, timeout=30, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA busy_timeout = 5000")
    return conn


def json_default(value):
    if hasattr(value, "item"):
        try:
            return value.item()
        except Exception:
            pass
    if isinstance(value, (datetime, timedelta)):
        return str(value)
    if isinstance(value, set):
        return list(value)
    return str(value)


def parse_timestamp(value):
    if not value:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S", "%H:%M:%S"):
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    return None


def get_exam_settings():
    with get_db_connection() as conn:
        row = conn.execute("SELECT * FROM exam_settings WHERE id=1").fetchone()
    if not row:
        return {
            "one_attempt_only": 0,
            "retake_allowed": 1,
            "max_attempts": 5,
            "cooldown_minutes": 0,
            "face_match_threshold": 0.72,
            "exam_duration_minutes": 60,
        }
    return dict(row)


def get_section_meta(section_key):
    return {
        "id": section_key,
        "title": f"{SECTION_LABELS.get(section_key, section_key.title())}: {'MCQs' if SECTION_TYPES.get(section_key) == 'mcq' else 'True or False' if SECTION_TYPES.get(section_key) == 'true_false' else 'Fill in the Blanks'}",
        "question_type": SECTION_TYPES.get(section_key, "mcq"),
        "marks_per_question": DEFAULT_SECTION_MARKS.get(section_key, 1),
        "questions": []
    }


def get_managed_question_bank(year_group):
    with get_db_connection() as conn:
        rows = conn.execute("""
            SELECT *
            FROM question_bank_entries
            WHERE year_group=?
            ORDER BY section_key, topic, difficulty, id
        """, (year_group,)).fetchall()

    if not rows:
        return QUESTION_BANKS.get(year_group)

    sections = {}
    for section_key in SECTION_ORDER:
        sections[section_key] = get_section_meta(section_key)

    for row in rows:
        options = []
        if row["options_json"]:
            try:
                options = json.loads(row["options_json"])
            except json.JSONDecodeError:
                options = []
        section = sections.setdefault(row["section_key"], get_section_meta(row["section_key"]))
        section["questions"].append({
            "id": f"DB{row['id']}",
            "question": row["question_text"],
            "options": options,
            "answer": row["answer_text"],
            "explanation": row["explanation"] or f"Topic: {row['topic']}",
        })

    ordered_sections = [sections[key] for key in SECTION_ORDER if sections.get(key) and sections[key]["questions"]]
    return {
        "paper_title": f"Year {year_group} Managed Assessment",
        "sections": ordered_sections
    }


def build_exam_with_bank(year_group, student_id):
    bank = get_managed_question_bank(year_group)
    if not bank:
        raise ValueError("Invalid year group")
    return build_exam_from_paper(bank, year_group, student_id)


def grade_exam_with_bank(year_group, student_id, answers):
    bank = get_managed_question_bank(year_group)
    if not bank:
        raise ValueError("Invalid year group")
    return grade_exam_submission_from_paper(bank, year_group, student_id, answers)


def determine_risk_band(score):
    if score >= 70:
        return "High"
    if score >= 35:
        return "Medium"
    return "Low"


def compute_risk_for_student(student_id, since_time=None):
    params = [student_id]
    query = "SELECT type, score FROM violations WHERE student_id=?"
    if since_time:
        query += " AND created_at >= ?"
        params.append(since_time.strftime("%Y-%m-%d %H:%M:%S"))
    with get_db_connection() as conn:
        rows = conn.execute(query, params).fetchall()
    total = sum(int(row["score"] or 0) for row in rows)
    return min(100, total), determine_risk_band(total)


def get_attempt_summary(student_id, year_group):
    settings = get_exam_settings()
    with get_db_connection() as conn:
        rows = conn.execute("""
            SELECT id, date
            FROM results
            WHERE student_id=? AND year_group=?
            ORDER BY id ASC
        """, (student_id, year_group)).fetchall()

    attempts_used = len(rows)
    max_attempts = 1 if settings["one_attempt_only"] else int(settings["max_attempts"] or 1)
    if not settings["retake_allowed"]:
        max_attempts = min(max_attempts, 1)
    allowed = True
    reason = ""
    available_at = None

    if attempts_used >= max_attempts:
        allowed = False
        reason = "Maximum attempts reached."
    elif attempts_used > 0 and int(settings["cooldown_minutes"] or 0) > 0:
        latest_attempt_time = parse_timestamp(rows[-1]["date"])
        if latest_attempt_time:
            available_at = latest_attempt_time + timedelta(minutes=int(settings["cooldown_minutes"]))
            if datetime.now() < available_at:
                allowed = False
                reason = f"Cooldown active until {available_at.strftime('%Y-%m-%d %H:%M:%S')}."

    return {
        "allowed": allowed,
        "reason": reason,
        "attempts_used": attempts_used,
        "max_attempts": max_attempts,
        "remaining_attempts": max(0, max_attempts - attempts_used),
        "cooldown_minutes": int(settings["cooldown_minutes"] or 0),
        "available_at": available_at.strftime("%Y-%m-%d %H:%M:%S") if available_at else "",
    }


def decode_data_url_to_image(data_url):
    if not data_url or "," not in str(data_url):
        return None
    try:
        _, encoded = data_url.split(",", 1)
        image_bytes = base64.b64decode(encoded)
        image = Image.open(io.BytesIO(image_bytes)).convert("L").resize((128, 128))
        image_array = np.array(image, dtype=np.uint8)
        image_array = cv2.equalizeHist(image_array)
        image_array = cv2.GaussianBlur(image_array, (5, 5), 0)
        return image_array.astype(np.float32)
    except Exception:
        return None


def compute_face_match_score(profile_path, live_image_data_url):
    if not profile_path or not os.path.exists(profile_path):
        return 0.0
    try:
        profile_image = Image.open(profile_path).convert("L").resize((128, 128))
        profile_array = np.array(profile_image, dtype=np.uint8)
        profile_array = cv2.equalizeHist(profile_array)
        profile_array = cv2.GaussianBlur(profile_array, (5, 5), 0).astype(np.float32)
    except Exception:
        return 0.0
    live_array = decode_data_url_to_image(live_image_data_url)
    if live_array is None:
        return 0.0

    profile_uint8 = profile_array.astype(np.uint8)
    live_uint8 = live_array.astype(np.uint8)

    diff_score = 1.0 - (np.mean(np.abs(profile_array - live_array)) / 255.0)
    histogram_score = cv2.compareHist(
        cv2.calcHist([profile_uint8], [0], None, [32], [0, 256]),
        cv2.calcHist([live_uint8], [0], None, [32], [0, 256]),
        cv2.HISTCMP_CORREL
    )
    histogram_score = max(0.0, min(1.0, (histogram_score + 1.0) / 2.0))

    structure_score = cv2.matchTemplate(profile_uint8, live_uint8, cv2.TM_CCOEFF_NORMED)[0][0]
    structure_score = max(0.0, min(1.0, (structure_score + 1.0) / 2.0))

    edge_profile = cv2.Canny(profile_uint8, 60, 140).astype(np.float32)
    edge_live = cv2.Canny(live_uint8, 60, 140).astype(np.float32)
    edge_gap = np.mean(np.abs(edge_profile - edge_live)) / 255.0
    edge_score = max(0.0, min(1.0, 1.0 - edge_gap))

    brightness_score = 1.0 - (abs(float(np.mean(profile_array)) - float(np.mean(live_array))) / 255.0)

    blended = (
        diff_score * 0.34 +
        structure_score * 0.28 +
        histogram_score * 0.20 +
        brightness_score * 0.10 +
        edge_score * 0.08
    )

    if diff_score > 0.72 and structure_score > 0.70:
        blended += 0.06
    if brightness_score < 0.55:
        blended -= 0.03

    return round(max(0.0, min(1.0, blended)), 3)


def build_student_suggestions(result_blob):
    suggestions = []
    if not result_blob:
        return suggestions
    try:
        analysis = json.loads(result_blob) if isinstance(result_blob, str) else result_blob
    except (TypeError, json.JSONDecodeError):
        return suggestions
    for section in analysis.get("section_results", []):
        total = int(section.get("total", 0) or 0)
        score = int(section.get("score", 0) or 0)
        if total <= 0:
            continue
        percentage = (score / total) * 100
        if percentage < 65:
            suggestions.append({
                "section": section.get("title", "Section"),
                "message": SUGGESTION_LIBRARY.get(section.get("id"), "Review this section and practice more targeted questions."),
                "score_text": f"{score} / {total}"
            })
    return suggestions[:3]


def create_notification(student_id, violation_type, severity, meta=None):
    created_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    message = f"{student_id}: {violation_type}"
    with get_db_connection() as conn:
        conn.execute("""
            INSERT INTO notifications (student_id, type, severity, message, status, created_at, metadata_json)
            VALUES (?, ?, ?, ?, 'open', ?, ?)
        """, (student_id, violation_type, severity, message, created_at, json.dumps(meta or {})))
        conn.commit()
    for admin_sid in list(ADMIN_SIDS):
        socketio.emit('admin_notification', {
            "student_id": student_id,
            "type": violation_type,
            "severity": severity,
            "message": message,
            "created_at": created_at
        }, room=admin_sid)


def refresh_live_exam(student_id, **kwargs):
    current = ACTIVE_EXAMS.get(student_id, {})
    current.update(kwargs)
    current["student_id"] = student_id
    current["last_seen"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    ACTIVE_EXAMS[student_id] = current


def build_pdf_document(title, sections, image_paths=None):
    font = ImageFont.load_default()
    pages = []
    page_width, page_height = 1240, 1754
    margin = 70

    def new_page():
        page = Image.new("RGB", (page_width, page_height), "white")
        draw = ImageDraw.Draw(page)
        draw.text((margin, margin), title, fill="black", font=font)
        return page, draw, margin + 40

    page, draw, y = new_page()
    for section_title, lines in sections:
        if y > page_height - 280:
            pages.append(page)
            page, draw, y = new_page()
        draw.text((margin, y), section_title, fill="black", font=font)
        y += 28
        for line in lines:
            if y > page_height - 220:
                pages.append(page)
                page, draw, y = new_page()
            draw.text((margin + 10, y), str(line)[:140], fill="black", font=font)
            y += 22
        y += 16

    if image_paths:
        for image_path in image_paths:
            if not image_path or not os.path.exists(image_path):
                continue
            if y > page_height - 440:
                pages.append(page)
                page, draw, y = new_page()
            try:
                proof = Image.open(image_path).convert("RGB")
                proof.thumbnail((420, 320))
                page.paste(proof, (margin, y))
                draw.text((margin + 440, y + 10), os.path.basename(image_path), fill="black", font=font)
                y += 350
            except Exception:
                continue

    pages.append(page)
    output = io.BytesIO()
    pages[0].save(output, format="PDF", save_all=True, append_images=pages[1:])
    output.seek(0)
    return output

# --- DATABASE INIT ---
def init_db():
    with sqlite3.connect(DB_NAME) as conn:
        c = conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS users 
                     (id TEXT PRIMARY KEY, name TEXT, password TEXT, role TEXT, 
                      branch TEXT, semester TEXT, phone TEXT, profile_pic TEXT)''')
        c.execute('''CREATE TABLE IF NOT EXISTS results 
                     (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id TEXT, score INTEGER, 
                     total INTEGER, violations TEXT, date TEXT)''')
        c.execute('''CREATE TABLE IF NOT EXISTS violations 
                     (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id TEXT, type TEXT, timestamp TEXT)''')
        c.execute('''CREATE TABLE IF NOT EXISTS login_activity
                     (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, role TEXT, login_at TEXT)''')
        c.execute('''CREATE TABLE IF NOT EXISTS exam_settings
                     (id INTEGER PRIMARY KEY CHECK (id = 1), one_attempt_only INTEGER DEFAULT 0,
                      retake_allowed INTEGER DEFAULT 1, max_attempts INTEGER DEFAULT 5,
                      cooldown_minutes INTEGER DEFAULT 0, face_match_threshold REAL DEFAULT 0.72,
                      exam_duration_minutes INTEGER DEFAULT 60)''')
        c.execute('''CREATE TABLE IF NOT EXISTS question_bank_entries
                     (id INTEGER PRIMARY KEY AUTOINCREMENT, year_group INTEGER, section_key TEXT,
                      topic TEXT, difficulty TEXT, question_text TEXT, options_json TEXT,
                      answer_text TEXT, explanation TEXT)''')
        c.execute('''CREATE TABLE IF NOT EXISTS notifications
                     (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id TEXT, type TEXT, severity TEXT,
                       message TEXT, status TEXT DEFAULT 'open', created_at TEXT, metadata_json TEXT)''')
        c.execute('''CREATE TABLE IF NOT EXISTS announcements
                     (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id TEXT, audience TEXT,
                      message TEXT, created_at TEXT, created_by TEXT)''')
        ensure_column_exists(c, "results", "year_group", "year_group INTEGER")
        ensure_column_exists(c, "results", "section_scores", "section_scores TEXT")
        ensure_column_exists(c, "results", "analysis_json", "analysis_json TEXT")
        ensure_column_exists(c, "results", "risk_score", "risk_score REAL DEFAULT 0")
        ensure_column_exists(c, "results", "risk_level", "risk_level TEXT DEFAULT 'Low'")
        ensure_column_exists(c, "results", "attempt_number", "attempt_number INTEGER DEFAULT 1")
        ensure_column_exists(c, "results", "admin_decision", "admin_decision TEXT DEFAULT 'pending'")
        ensure_column_exists(c, "results", "decision_notes", "decision_notes TEXT")
        ensure_column_exists(c, "users", "email", "email TEXT")
        ensure_column_exists(c, "users", "recovery_methods", "recovery_methods TEXT")
        ensure_column_exists(c, "users", "google_sub", "google_sub TEXT")
        ensure_column_exists(c, "users", "google_email", "google_email TEXT")
        ensure_column_exists(c, "violations", "evidence_path", "evidence_path TEXT")
        ensure_column_exists(c, "violations", "severity", "severity TEXT DEFAULT 'low'")
        ensure_column_exists(c, "violations", "score", "score INTEGER DEFAULT 0")
        ensure_column_exists(c, "violations", "created_at", "created_at TEXT")
        c.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_sub ON users(google_sub) WHERE google_sub IS NOT NULL")
        c.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_email ON users(google_email) WHERE google_email IS NOT NULL")
        c.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email COLLATE NOCASE) WHERE email IS NOT NULL")
        c.execute("""
            INSERT OR IGNORE INTO exam_settings
            (id, one_attempt_only, retake_allowed, max_attempts, cooldown_minutes, face_match_threshold, exam_duration_minutes)
            VALUES (1, 0, 1, 5, 0, 0.72, 60)
        """)
        
        if ADMIN_INITIAL_PASSWORD:
            c.execute(
                "INSERT OR IGNORE INTO users (id, name, password, role, semester) VALUES (?, ?, ?, ?, ?)",
                (
                    ADMIN_USERNAME,
                    "Administrator",
                    generate_password_hash(ADMIN_INITIAL_PASSWORD),
                    "admin",
                    "N/A",
        ),
    )
        conn.commit()

prepare_database_file()
init_db()

def get_model():
    global YOLO_MODEL, YOLO_MODEL_FAILED_AT
    if YOLO_MODEL is False:
        if YOLO_MODEL_FAILED_AT and (datetime.now() - YOLO_MODEL_FAILED_AT).total_seconds() < MODEL_LOAD_RETRY_SECONDS:
            return None
        YOLO_MODEL = None
        YOLO_MODEL_FAILED_AT = None
    if YOLO_MODEL is None:
        try:
            gc.collect()
            from ultralytics import YOLO as UltralyticsYOLO
            YOLO_MODEL = UltralyticsYOLO('yolov8n.pt')
        except Exception as error:
            app.logger.exception("YOLO model unavailable: %s", error)
            YOLO_MODEL = False
            YOLO_MODEL_FAILED_AT = datetime.now()
            return None
    return YOLO_MODEL


def get_face_detector():
    global FACE_CASCADE
    if FACE_CASCADE is None:
        cascade_path = os.path.join(cv2.data.haarcascades, "haarcascade_frontalface_default.xml")
        detector = cv2.CascadeClassifier(cascade_path)
        if detector.empty():
            app.logger.warning("Failed to load face cascade from %s", cascade_path)
        FACE_CASCADE = detector
    return FACE_CASCADE


def get_student_year_group(student_id):
    with get_db_connection() as conn:
        user = conn.execute("SELECT semester FROM users WHERE id=?", (student_id,)).fetchone()

    if not user or not user[0]:
        return None

    try:
        return int(str(user[0]).split('-')[0])
    except (ValueError, IndexError):
        return None


def is_valid_semester(value):
    return bool(re.match(r"^[1-4]-[1-2]$", str(value or "").strip()))


def get_year_group_from_semester(semester_value, default=1):
    try:
        return int(str(semester_value).split('-')[0])
    except (ValueError, IndexError, AttributeError):
        return default


def build_weak_topic_summary(result_rows):
    topic_totals = {}

    for row in result_rows:
        analysis_blob = row[5] if len(row) > 5 else None
        if not analysis_blob:
            continue

        try:
            analysis = json.loads(analysis_blob)
        except (TypeError, json.JSONDecodeError):
            continue

        for section in analysis.get("section_results", []):
            topic_key = section.get("id") or section.get("title") or "topic"
            topic_entry = topic_totals.setdefault(topic_key, {
                "title": section.get("title", "General Topic"),
                "earned": 0,
                "possible": 0,
                "attempts": 0
            })
            topic_entry["earned"] += int(section.get("score", 0) or 0)
            topic_entry["possible"] += int(section.get("total", 0) or 0)
            topic_entry["attempts"] += 1

    weak_topics = []
    for topic in topic_totals.values():
        if topic["possible"] <= 0:
            continue
        accuracy = round((topic["earned"] / topic["possible"]) * 100, 1)
        weak_topics.append({
            "title": topic["title"],
            "accuracy": accuracy,
            "attempts": topic["attempts"],
            "earned": topic["earned"],
            "possible": topic["possible"]
        })

    return sorted(weak_topics, key=lambda item: (item["accuracy"], item["possible"]))[:3]


def build_topic_performance_summary(result_rows):
    topic_totals = {}

    for row in result_rows:
        analysis_blob = row[5] if len(row) > 5 else None
        if not analysis_blob:
            continue

        try:
            analysis = json.loads(analysis_blob)
        except (TypeError, json.JSONDecodeError):
            continue

        for section in analysis.get("section_results", []):
            topic_key = section.get("id") or section.get("title") or "topic"
            topic_entry = topic_totals.setdefault(topic_key, {
                "title": section.get("title", "General Topic"),
                "earned": 0,
                "possible": 0,
                "attempts": 0
            })
            topic_entry["earned"] += int(section.get("score", 0) or 0)
            topic_entry["possible"] += int(section.get("total", 0) or 0)
            topic_entry["attempts"] += 1

    summary = []
    for topic in topic_totals.values():
        if topic["possible"] <= 0:
            continue
        accuracy = round((topic["earned"] / topic["possible"]) * 100, 1)
        summary.append({
            "title": topic["title"],
            "accuracy": accuracy,
            "attempts": topic["attempts"],
            "earned": topic["earned"],
            "possible": topic["possible"]
        })

    return sorted(summary, key=lambda item: (-item["accuracy"], -item["possible"], item["title"]))


def build_retake_recommendation(attempt_summary, latest_risk, latest_trend, average_score, strongest_topic, weakest_topic):
    if not attempt_summary.get("allowed"):
        return "Retake locked right now. Focus on revision until the next attempt window opens."
    if latest_risk.get("level") == "High":
        return "Retake carefully after a clean environment check. Your last attempt showed high proctoring risk."
    if average_score >= 40:
        return "You are performing strongly. Retake only if you want to push toward a top leaderboard spot."
    if latest_trend > 0 and strongest_topic:
        return f"Your trend is improving. Keep momentum and reinforce {strongest_topic['title']} before the next attempt."
    if weakest_topic:
        return f"Retake is recommended after focused practice on {weakest_topic['title']} and a short revision cycle."
    return "A retake can help. Review the latest analysis, strengthen weak areas, and attempt when ready."


def build_student_badges(student_results, latest_risk, latest_trend, student_rank):
    badges = []
    if student_results:
        clean_attempts = sum(1 for row in student_results if float(row[6] or 0) < 20)
        if clean_attempts >= 1:
            badges.append({
                "title": "Clean Attempt",
                "description": f"{clean_attempts} saved attempt{'s' if clean_attempts != 1 else ''} stayed below the risk warning range."
            })
        if latest_trend > 0:
            badges.append({
                "title": "Rising Score",
                "description": f"Your latest attempt improved by {latest_trend} mark{'s' if latest_trend != 1 else ''}."
            })
        if latest_risk.get("level") == "Low":
            badges.append({
                "title": "Trusted Presence",
                "description": "Your latest saved attempt finished with a low proctoring risk level."
            })
        if student_rank and int(student_rank.get("rank", 999)) <= 3:
            badges.append({
                "title": "Top 3 Rank",
                "description": "You are currently among the top performers on the leaderboard."
            })
    return badges[:4]

# --- AUTH ROUTES ---
@app.route('/', methods=['GET', 'POST'])
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # All IDs are treated as Uppercase for consistency
        uid = request.form.get('user_id', '').strip().upper()
        pwd = request.form.get('password', '')
        with get_db_connection() as conn:
            user = conn.execute("SELECT * FROM users WHERE id=?", (uid,)).fetchone()
        
        if user and check_password_hash(user[2], pwd):
            session['user_id'], session['name'], session['role'] = user[0], user[1], user[3]
            if user[3] == 'student':
                with get_db_connection() as activity_conn:
                    activity_conn.execute(
                        "INSERT INTO login_activity (user_id, role, login_at) VALUES (?, ?, ?)",
                        (user[0], user[3], datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
                    )
                    activity_conn.commit()
            if user[3] == 'admin':
                return redirect(url_for('admin_dashboard'))
            else:
                return redirect(url_for('student_dashboard'))
        return render_template('login.html', error="Invalid Credentials")
    return render_template('login.html', error=request.args.get("google_error", ""))


@app.route('/auth/google')
def google_login():
    if not google_oauth_enabled():
        return redirect(url_for('login', google_error='Google sign-in is not configured yet. Add the Google OAuth credentials to enable it.'))

    state = secrets.token_urlsafe(32)
    redirect_uri = get_google_redirect_uri()
    session['google_oauth_state'] = state
    session['google_redirect_uri'] = redirect_uri
    params = urlencode({
        'client_id': GOOGLE_CLIENT_ID,
        'redirect_uri': redirect_uri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'state': state,
        'prompt': 'select_account',
    })
    return redirect(f'https://accounts.google.com/o/oauth2/v2/auth?{params}')


@app.route('/auth/google/callback')
def google_callback():
    state = request.args.get('state', '')
    expected_state = session.pop('google_oauth_state', '')
    redirect_uri = session.pop('google_redirect_uri', '') or get_google_redirect_uri()
    if not state or not expected_state or not secrets.compare_digest(state, expected_state):
        return redirect(url_for('login', google_error='Google sign-in could not verify this session. Please try again.'))

    if request.args.get('error'):
        return redirect(url_for('login', google_error='Google sign-in was cancelled or denied.'))

    code = request.args.get('code', '')
    if not code:
        return redirect(url_for('login', google_error='Google did not return an authorization code.'))

    try:
        token_data = exchange_google_code(code, redirect_uri)
        identity = verify_google_identity(token_data.get('id_token', ''))
    except HTTPError as error:
        app.logger.warning('Google token exchange failed with HTTP status %s.', error.code)
        return redirect(url_for('login', google_error='Google rejected the OAuth client configuration. Check the Client Secret in your local .env file, then try again.'))
    except URLError:
        app.logger.warning('Google token verification could not reach Google services.')
        return redirect(url_for('login', google_error='ProctorX could not reach Google to verify your sign-in. Check your internet connection and try again.'))
    except (ValueError, ImportError) as error:
        app.logger.warning('Google identity verification failed: %s', type(error).__name__)
        return redirect(url_for('login', google_error='Google returned an identity response ProctorX could not verify. Please try again.'))
    except Exception:
        app.logger.exception('Unexpected Google sign-in failure')
        return redirect(url_for('login', google_error='Google sign-in is temporarily unavailable. Please try again.'))

    google_email = identity['email'].strip().lower()
    with get_db_connection() as conn:
        user = conn.execute('SELECT * FROM users WHERE google_sub=?', (identity['sub'],)).fetchone()
        email_account = conn.execute(
            'SELECT id FROM users WHERE google_email=? OR email=? COLLATE NOCASE',
            (google_email, google_email),
        ).fetchone()

        if user:
            conn.execute(
                'INSERT INTO login_activity (user_id, role, login_at) VALUES (?, ?, ?)',
                (user['id'], 'student', datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
            )
            conn.commit()
            session.clear()
            session['user_id'], session['name'], session['role'] = user['id'], user['name'], 'student'
            return redirect(url_for('student_dashboard'))

        if email_account:
            return redirect(url_for('login', google_error='An account already exists for this Google email. Use its existing sign-in method.'))

    session['google_pending_profile'] = {
        'sub': identity['sub'],
        'email': google_email,
        'name': str(identity.get('name') or google_email.split('@')[0]).strip()[:80],
    }
    return redirect(url_for('complete_google_profile'))


@app.route('/auth/google/complete-profile', methods=['GET', 'POST'])
def complete_google_profile():
    pending_profile = session.get('google_pending_profile')
    if not pending_profile:
        return redirect(url_for('login', google_error='Start with Google sign-in before completing a profile.'))

    if request.method == 'GET':
        return render_template('google_profile.html', google_profile=pending_profile)

    name = request.form.get('name', '').strip()
    user_id = request.form.get('userid', '').strip().upper()
    branch = request.form.get('branch', '').strip()
    semester = request.form.get('semester', '').strip()
    phone = request.form.get('phone', '').strip()
    file = request.files.get('profile_pic')

    if not name or not user_id or not branch or not is_valid_semester(semester) or not phone:
        return jsonify({'status': 'error', 'message': 'Complete every required profile field before continuing.'}), 400
    if not re.match(r'^[A-Z0-9]{10}$', user_id):
        return jsonify({'status': 'error', 'message': 'Roll Number must be exactly 10 alphanumeric characters.'}), 400
    if not file or not file.filename or not allowed_file(file.filename) or not is_valid_profile_image(file):
        return jsonify({'status': 'error', 'message': 'Upload a valid PNG, JPG, or JPEG profile photo.'}), 400

    extension = file.filename.rsplit('.', 1)[1].lower()
    filename = secure_filename(f'{user_id}_profile.{extension}')
    file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))

    try:
        with get_db_connection() as conn:
            if conn.execute('SELECT id FROM users WHERE id=?', (user_id,)).fetchone():
                return jsonify({'status': 'error', 'message': 'That roll number is already registered.'}), 400
            if conn.execute('SELECT id FROM users WHERE google_sub=? OR google_email=?', (pending_profile['sub'], pending_profile['email'])).fetchone():
                return jsonify({'status': 'error', 'message': 'This Google account is already linked to a ProctorX profile.'}), 400
            conn.execute('''
                INSERT INTO users (id, name, password, role, branch, semester, phone, profile_pic, google_sub, google_email)
                VALUES (?, ?, ?, 'student', ?, ?, ?, ?, ?, ?)
            ''', (
                user_id, name, generate_password_hash(secrets.token_urlsafe(32)), branch, semester, phone,
                filename, pending_profile['sub'], pending_profile['email'],
            ))
            conn.execute(
                'INSERT INTO login_activity (user_id, role, login_at) VALUES (?, ?, ?)',
                (user_id, 'student', datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
            )
            conn.commit()
    except sqlite3.IntegrityError:
        return jsonify({'status': 'error', 'message': 'This Google account or roll number is already registered.'}), 400

    session.clear()
    session['user_id'], session['name'], session['role'] = user_id, name, 'student'
    return jsonify({'status': 'success', 'redirect_url': url_for('student_dashboard')})

@app.route('/register')
def register_page():
    return render_template('register.html')

@app.route('/forgot_password', methods=['GET', 'POST'])
def forgot_password():
    if request.method != 'POST':
        return render_template('forgot_password.html')

    action = request.form.get('action', 'phone_reset')
    userid = request.form.get('userid', '').strip().upper()
    new_password = request.form.get('new_password', '')

    if action == 'request_email_otp':
        email = normalize_email_address(request.form.get('email'))
        if not userid or not email:
            return render_template('forgot_password.html', error="Enter your roll number and registered email address.", mode='email')

        with get_db_connection() as conn:
            user = conn.execute(
                """
                SELECT id, email, google_email, recovery_methods, google_sub
                FROM users
                WHERE id=? AND (email=? COLLATE NOCASE OR google_email=? COLLATE NOCASE)
                """,
                (userid, email, email),
            ).fetchone()

        # Google accounts already provide a verified email, so email recovery is enabled for them automatically.
        email_recovery_enabled = user and (bool(user['google_sub']) or 'email' in selected_recovery_methods(user['recovery_methods']))
        if not email_recovery_enabled:
            return render_template('forgot_password.html', error="Email recovery is not available for this account. Choose phone verification or contact your administrator.", mode='email')

        code = f"{secrets.randbelow(1_000_000):06d}"
        try:
            send_password_reset_otp(email, code)
        except (OSError, smtplib.SMTPException, RuntimeError):
            app.logger.exception('Unable to send password reset email')
            return render_template('forgot_password.html', error="We could not send a reset email right now. Please try phone verification or contact your administrator.", mode='email')

        session['password_reset_otp'] = {
            'user_id': userid,
            'email': email,
            'code_hash': generate_password_hash(code),
            'expires_at': (datetime.utcnow() + timedelta(minutes=10)).isoformat(),
            'attempts': 0,
        }
        return render_template('forgot_password.html', mode='otp', userid=userid, email=email)

    if action == 'confirm_email_otp':
        otp_session = session.get('password_reset_otp') or {}
        code = request.form.get('otp', '').strip()
        if not otp_session or not code or len(new_password) < 8:
            return render_template('forgot_password.html', error="Enter the six-digit code and a password with at least 8 characters.", mode='otp', userid=otp_session.get('user_id'), email=otp_session.get('email'))

        expired = datetime.utcnow() > datetime.fromisoformat(otp_session['expires_at'])
        attempts = int(otp_session.get('attempts', 0))
        if expired or attempts >= 5 or not check_password_hash(otp_session['code_hash'], code):
            otp_session['attempts'] = attempts + 1
            session['password_reset_otp'] = otp_session
            return render_template('forgot_password.html', error="That code is invalid or expired. Request a new code and try again.", mode='email')

        with get_db_connection() as conn:
            conn.execute("UPDATE users SET password=? WHERE id=?", (generate_password_hash(new_password), otp_session['user_id']))
            conn.commit()
        session.pop('password_reset_otp', None)
        return render_template('login.html', success="Password reset successful! Please login.")

    phone = request.form.get('phone', '').strip()
    if not userid or not phone or len(new_password) < 8:
        return render_template('forgot_password.html', error="Enter your ID, phone number, and a password with at least 8 characters.")

    with get_db_connection() as conn:
        user = conn.execute("SELECT id, recovery_methods FROM users WHERE id=? AND phone=?", (userid, phone)).fetchone()
        if user and ('phone' in selected_recovery_methods(user['recovery_methods']) or not user['recovery_methods']):
            conn.execute("UPDATE users SET password=? WHERE id=?", (generate_password_hash(new_password), userid))
            conn.commit()
            return render_template('login.html', success="Password reset successful! Please login.")
    return render_template('forgot_password.html', error="Identity verification failed or phone recovery is not enabled for this account.")

@app.route('/register_user', methods=['POST'])
def register_user():
    name = request.form.get('name', '').strip()
    userid = request.form.get('userid', '').strip().upper()
    email = normalize_email_address(request.form.get('email'))
    branch = request.form.get('branch', '').strip()
    semester = request.form.get('semester', '').strip()
    phone = request.form.get('phone', '').strip()
    password = request.form.get('password', '')
    file = request.files.get('profile_pic')
    recovery_methods = sorted(set(request.form.getlist('recovery_methods')) & {'phone', 'email'})

    if not name:
        return jsonify({"status": "error", "message": "Full Name is required."}), 400
    if not userid:
        return jsonify({"status": "error", "message": "Roll Number is required."}), 400
    if not email:
        return jsonify({"status": "error", "message": "Enter a valid email address."}), 400
    if not branch:
        return jsonify({"status": "error", "message": "Branch is required."}), 400
    if not semester:
        return jsonify({"status": "error", "message": "Semester is required."}), 400
    if not is_valid_semester(semester):
        return jsonify({"status": "error", "message": "Semester must be in the format 1-1 to 4-2."}), 400
    if not phone:
        return jsonify({"status": "error", "message": "Phone Number is required."}), 400
    if not password:
        return jsonify({"status": "error", "message": "Password is required."}), 400
    if len(password) < 8:
        return jsonify({"status": "error", "message": "Password must contain at least 8 characters."}), 400
    if not recovery_methods:
        return jsonify({"status": "error", "message": "Choose at least one password recovery method."}), 400
    if not file or not file.filename:
        return jsonify({"status": "error", "message": "Profile photo is required."}), 400
    if not allowed_file(file.filename):
        return jsonify({"status": "error", "message": "Profile photo must be PNG, JPG, or JPEG."}), 400
    if not is_valid_profile_image(file):
        return jsonify({"status": "error", "message": "Profile photo must be a valid image file."}), 400

    if not re.match(r"^[A-Z0-9]{10}$", userid):
        return jsonify({"status": "error", "message": "Roll Number must be exactly 10 alphanumeric characters."}), 400

    try:
        with get_db_connection() as conn:
            if conn.execute("SELECT id FROM users WHERE id=?", (userid,)).fetchone():
                return jsonify({"status": "error", "message": "UserID already exists!"}), 400
            if conn.execute("SELECT id FROM users WHERE email=? COLLATE NOCASE OR google_email=?", (email, email)).fetchone():
                return jsonify({"status": "error", "message": "An account already exists for this email address."}), 400
            
            filename = secure_filename(f"{userid}_profile.{file.filename.rsplit('.', 1)[1]}")
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            pic_filename = filename

            hashed_pwd = generate_password_hash(password)
            conn.execute("""
                INSERT INTO users (id, name, password, role, branch, semester, phone, profile_pic, email, recovery_methods)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (userid, name, hashed_pwd, "student", branch, semester, phone, pic_filename, email, ','.join(recovery_methods)))
            conn.commit()
        return jsonify({"status": "success", "message": "User created successfully!"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# --- DASHBOARDS ---

@app.route('/student_dashboard')
def student_dashboard():
    if session.get('role') != 'student': return redirect(url_for('login'))
    with get_db_connection() as conn:
        user = conn.execute(
            "SELECT id, name, branch, semester, phone, profile_pic FROM users WHERE id=?",
            (session['user_id'],)
        ).fetchone()
        student_results = conn.execute("""
            SELECT id, score, total, date, year_group, analysis_json, risk_score, risk_level, admin_decision
            FROM results
            WHERE student_id=?
            ORDER BY id ASC
        """, (session['user_id'],)).fetchall()
        leaderboard_rows = conn.execute("""
            SELECT r.student_id, u.name, ROUND(AVG(r.score), 2) AS avg_score,
                   MAX(r.score) AS best_score, COUNT(*) AS attempts
            FROM results r
            JOIN users u ON r.student_id = u.id
            WHERE u.role='student'
            GROUP BY r.student_id, u.name
            ORDER BY avg_score DESC, best_score DESC, attempts DESC, u.name ASC
        """).fetchall()
    
    current_sem_str = user[3] if user else "1-1"
    group_id = get_year_group_from_semester(current_sem_str, 1)
    attempt_summary = get_attempt_summary(session['user_id'], group_id)

    attempts_count = len(student_results)
    score_history_labels = [f"Attempt {index}" for index, _ in enumerate(student_results, start=1)]
    score_history_values = [row[1] for row in student_results]
    average_score = round(sum(score_history_values) / attempts_count, 1) if attempts_count else 0
    best_score = max(score_history_values) if attempts_count else 0
    latest_score = score_history_values[-1] if attempts_count else 0
    latest_trend = latest_score - score_history_values[-2] if attempts_count > 1 else 0
    weak_topics = build_weak_topic_summary(student_results)
    latest_analysis = student_results[-1][5] if student_results else None
    improvement_suggestions = build_student_suggestions(latest_analysis)
    latest_result_id = student_results[-1][0] if student_results else None
    latest_risk = {
        "score": float(student_results[-1][6] or 0) if student_results else 0,
        "level": student_results[-1][7] if student_results else "Low",
        "decision": student_results[-1][8] if student_results else "pending"
    }
    topic_performance = build_topic_performance_summary(student_results)
    strongest_topic = topic_performance[0] if topic_performance else None
    weakest_topic = topic_performance[-1] if topic_performance else None

    recent_attempts = []
    for row in reversed(student_results[-5:]):
        recent_attempts.append({
            "id": row[0],
            "score": row[1],
            "total": row[2],
            "date": row[3],
            "year_group": row[4] if row[4] else get_year_group_from_semester(current_sem_str, 1),
            "risk_score": row[6] or 0,
            "risk_level": row[7] or "Low",
            "admin_decision": row[8] or "pending"
        })

    leaderboard = []
    student_rank = None
    for index, row in enumerate(leaderboard_rows, start=1):
        entry = {
            "rank": index,
            "student_id": row[0],
            "name": row[1],
            "avg_score": float(row[2] or 0),
            "best_score": row[3] or 0,
            "attempts": row[4] or 0
        }
        if index <= 5:
            leaderboard.append(entry)
        if row[0] == session['user_id']:
            student_rank = entry

    retake_recommendation = build_retake_recommendation(
        attempt_summary,
        latest_risk,
        latest_trend,
        average_score,
        strongest_topic,
        weakest_topic
    )
    achievement_badges = build_student_badges(student_results, latest_risk, latest_trend, student_rank)
    
    student_profile = {
        "id": user[0] if user else session['user_id'],
        "name": user[1] if user else session.get('name', ''),
        "branch": user[2] if user else '',
        "semester": current_sem_str,
        "phone": user[4] if user else '',
        "profile_pic": user[5] if user and user[5] else '',
        "has_profile_pic": bool(user and user[5] and user[5] != 'default.png')
    }

    return render_template(
        'student_dashboard_theme.html',
        group_id=group_id,
        current_sem=current_sem_str,
        student_profile=student_profile,
        attempts_count=attempts_count,
        average_score=average_score,
        best_score=best_score,
        latest_score=latest_score,
        latest_trend=latest_trend,
        score_history_labels=score_history_labels,
        score_history_values=score_history_values,
        recent_attempts=recent_attempts,
        weak_topics=weak_topics,
        improvement_suggestions=improvement_suggestions,
        leaderboard=leaderboard,
        student_rank=student_rank,
        attempt_summary=attempt_summary,
        latest_result_id=latest_result_id,
        latest_risk=latest_risk,
        strongest_topic=strongest_topic,
        weakest_topic=weakest_topic,
        retake_recommendation=retake_recommendation,
        achievement_badges=achievement_badges
    )


@app.route('/student/profile')
def student_profile_page():
    if session.get('role') != 'student':
        return redirect(url_for('login'))

    with get_db_connection() as conn:
        user = conn.execute(
            "SELECT id, name, branch, semester, phone, profile_pic FROM users WHERE id=?",
            (session['user_id'],)
        ).fetchone()

    if not user:
        return redirect(url_for('student_dashboard'))

    student_profile = {
        "id": user[0],
        "name": user[1] or session.get('name', ''),
        "branch": user[2] or '',
        "semester": user[3] or '1-1',
        "phone": user[4] or '',
        "profile_pic": user[5] or '',
        "has_profile_pic": bool(user[5] and user[5] != 'default.png')
    }

    return render_template('student_profile.html', student_profile=student_profile)


@app.route('/student/update_profile', methods=['POST'])
def update_student_profile():
    if session.get('role') != 'student':
        return jsonify({"status": "error", "message": "Unauthorized"}), 403

    name = request.form.get('name', '').strip()
    branch = request.form.get('branch', '').strip()
    semester = request.form.get('semester', '').strip()
    phone = request.form.get('phone', '').strip()
    file = request.files.get('profile_pic')

    if not name:
        return jsonify({"status": "error", "message": "Name is required."}), 400
    if not branch:
        return jsonify({"status": "error", "message": "Branch is required."}), 400
    if not is_valid_semester(semester):
        return jsonify({"status": "error", "message": "Semester must be in the format 1-1 to 4-2."}), 400
    if not phone:
        return jsonify({"status": "error", "message": "Phone number is required."}), 400

    try:
        with get_db_connection() as conn:
            current_user = conn.execute(
                "SELECT profile_pic FROM users WHERE id=? AND role='student'",
                (session['user_id'],)
            ).fetchone()

            if not current_user:
                return jsonify({"status": "error", "message": "Student profile not found."}), 404

            profile_pic = current_user[0] or "default.png"
            if file and file.filename:
                if not allowed_file(file.filename):
                    return jsonify({"status": "error", "message": "Profile picture must be PNG, JPG, or JPEG."}), 400
                if not is_valid_profile_image(file):
                    return jsonify({"status": "error", "message": "Profile picture must be a valid image file."}), 400
                extension = file.filename.rsplit('.', 1)[1].lower()
                filename = secure_filename(f"{session['user_id']}_profile.{extension}")
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
                profile_pic = filename

            conn.execute("""
                UPDATE users
                SET name=?, branch=?, semester=?, phone=?, profile_pic=?
                WHERE id=? AND role='student'
            """, (name, branch, semester, phone, profile_pic, session['user_id']))
            conn.commit()

        session['name'] = name
        return jsonify({"status": "success", "message": "Profile updated successfully."})
    except Exception as exc:
        return jsonify({"status": "error", "message": str(exc)}), 500

@app.route('/admin/dashboard')
def admin_dashboard():
    if session.get('role') != 'admin': return redirect(url_for('login'))
    filters = {
        "branch": request.args.get("branch", "").strip(),
        "semester": request.args.get("semester", "").strip(),
        "date": request.args.get("date", "").strip(),
        "year_group": request.args.get("year_group", "").strip(),
    }
    record_filters = []
    record_params = []
    if filters["branch"]:
        record_filters.append("u.branch=?")
        record_params.append(filters["branch"])
    if filters["semester"]:
        record_filters.append("u.semester=?")
        record_params.append(filters["semester"])
    if filters["date"]:
        record_filters.append("SUBSTR(r.date, 1, 10)=?")
        record_params.append(filters["date"])
    if filters["year_group"]:
        record_filters.append("r.year_group=?")
        record_params.append(filters["year_group"])
    record_where = ("WHERE " + " AND ".join(record_filters)) if record_filters else ""

    violation_filters = []
    violation_params = []
    if filters["branch"]:
        violation_filters.append("u.branch=?")
        violation_params.append(filters["branch"])
    if filters["semester"]:
        violation_filters.append("u.semester=?")
        violation_params.append(filters["semester"])
    if filters["date"]:
        violation_filters.append("SUBSTR(v.created_at, 1, 10)=?")
        violation_params.append(filters["date"])
    violation_where = ("WHERE " + " AND ".join(violation_filters)) if violation_filters else ""

    with get_db_connection() as conn:
        submits = conn.execute("SELECT count(*) FROM results").fetchone()[0]
        viols = conn.execute("SELECT count(*) FROM violations").fetchone()[0]
        avg_score = round(conn.execute("SELECT AVG(score) FROM results").fetchone()[0] or 0, 1)
        total_student_logins = conn.execute(
            "SELECT count(*) FROM login_activity WHERE role='student'"
        ).fetchone()[0]
        active_login_students = conn.execute(
            "SELECT count(DISTINCT user_id) FROM login_activity WHERE role='student'"
        ).fetchone()[0]
        
        # Correct Year-wise statistics
        year_stats = {}
        for y in range(1, 5):
            count = conn.execute("""
                SELECT count(*) FROM results r 
                JOIN users u ON r.student_id = u.id 
                WHERE u.semester LIKE ?""", (f"{y}-%",)).fetchone()[0]
            year_stats[y] = count

        semester_score_rows = conn.execute("""
            SELECT u.semester, ROUND(AVG(r.score), 2) AS avg_score
            FROM results r
            JOIN users u ON r.student_id = u.id
            WHERE u.role='student'
            GROUP BY u.semester
            ORDER BY CAST(SUBSTR(u.semester, 1, 1) AS INTEGER),
                     CAST(SUBSTR(u.semester, 3, 1) AS INTEGER)
        """).fetchall()
        score_rows = conn.execute("SELECT score FROM results").fetchall()
        recent_logins = conn.execute("""
            SELECT l.user_id, u.name, l.login_at
            FROM login_activity l
            JOIN users u ON l.user_id = u.id
            WHERE l.role='student'
            ORDER BY l.id DESC
            LIMIT 10
        """).fetchall()
        login_rows = conn.execute("""
            SELECT SUBSTR(login_at, 1, 10) AS login_day, COUNT(*)
            FROM login_activity
            WHERE role='student'
            GROUP BY login_day
            ORDER BY login_day DESC
            LIMIT 7
        """).fetchall()
        improvement_rows = conn.execute("""
            SELECT r.student_id, u.name, r.score, r.date
            FROM results r
            JOIN users u ON r.student_id = u.id
            WHERE u.role='student'
            ORDER BY r.student_id, r.date
        """).fetchall()
        all_students = conn.execute("SELECT id, name, branch, semester, phone, profile_pic FROM users WHERE role='student'").fetchall()
        logs = conn.execute(f"""
            SELECT v.id, v.student_id, u.name, v.type, v.timestamp, v.evidence_path, v.severity, v.score, v.created_at
            FROM violations v
            JOIN users u ON v.student_id = u.id
            {violation_where}
            ORDER BY v.id DESC
            LIMIT 100
        """, violation_params).fetchall()
        records = conn.execute(f"""
            SELECT r.id, r.student_id, u.name, u.branch, u.semester, r.score, r.total, r.date,
                   r.year_group, r.risk_score, r.risk_level, r.admin_decision
            FROM results r
            JOIN users u ON r.student_id = u.id
            {record_where}
            ORDER BY r.id DESC
        """, record_params).fetchall()
        qb_rows = conn.execute("""
            SELECT id, year_group, section_key, topic, difficulty, question_text, answer_text
            FROM question_bank_entries
            ORDER BY year_group, section_key, topic, difficulty, id DESC
        """).fetchall()
        notifications = conn.execute("""
            SELECT id, student_id, type, severity, message, created_at, status
            FROM notifications
            ORDER BY id DESC
            LIMIT 12
        """).fetchall()
        announcements = conn.execute("""
            SELECT id, student_id, audience, message, created_at, created_by
            FROM announcements
            ORDER BY id DESC
            LIMIT 12
        """).fetchall()

    marks_distribution = {
        "0-20": 0,
        "21-30": 0,
        "31-40": 0,
        "41-50": 0
    }
    for score_row in score_rows:
        score = score_row[0]
        if score <= 20:
            marks_distribution["0-20"] += 1
        elif score <= 30:
            marks_distribution["21-30"] += 1
        elif score <= 40:
            marks_distribution["31-40"] += 1
        else:
            marks_distribution["41-50"] += 1

    login_counts_by_day = {row[0]: row[1] for row in login_rows}
    login_trend_labels = []
    login_trend_values = []
    for days_ago in range(6, -1, -1):
        day = datetime.now().date() - timedelta(days=days_ago)
        day_key = day.strftime("%Y-%m-%d")
        login_trend_labels.append(day.strftime("%d %b"))
        login_trend_values.append(login_counts_by_day.get(day_key, 0))

    performance_by_student = {}
    for student_id, student_name, score, attempt_date in improvement_rows:
        performance_by_student.setdefault(student_id, {
            "student_id": student_id,
            "name": student_name,
            "scores": []
        })["scores"].append({"score": score, "date": attempt_date})

    improvement_summary = []
    for student_data in performance_by_student.values():
        scores = student_data["scores"]
        if len(scores) < 2:
            continue

        first_score = scores[0]["score"]
        latest_score = scores[-1]["score"]
        score_change = latest_score - first_score
        improvement_summary.append({
            "student_id": student_data["student_id"],
            "name": student_data["name"],
            "first_score": first_score,
            "latest_score": latest_score,
            "change": score_change,
            "latest_date": scores[-1]["date"]
        })

    top_improvers = [
        item for item in sorted(
            improvement_summary,
            key=lambda entry: (entry["change"], entry["latest_score"]),
            reverse=True
        )
        if item["change"] > 0
    ][:5]
    improved_students = sum(1 for item in improvement_summary if item["change"] > 0)
    live_exams = sorted(ACTIVE_EXAMS.values(), key=lambda item: item.get("last_seen", ""), reverse=True)
    exam_settings = get_exam_settings()
    filter_options = {
        "branches": sorted({row[2] for row in all_students if row[2]}),
        "semesters": sorted({row[3] for row in all_students if row[3]}),
    }

    return render_template(
        'admin_dashboard_stats.html',
        submissions=submits,
        violation_count=viols,
        avg_score=avg_score,
        total_student_logins=total_student_logins,
        active_login_students=active_login_students,
        improved_students=improved_students,
        year_stats=year_stats,
        marks_chart_labels=[row[0] for row in semester_score_rows],
        marks_chart_values=[row[1] for row in semester_score_rows],
        marks_distribution_labels=list(marks_distribution.keys()),
        marks_distribution_values=list(marks_distribution.values()),
        login_trend_labels=login_trend_labels,
        login_trend_values=login_trend_values,
        recent_logins=recent_logins,
        top_improvers=top_improvers,
        has_exam_data=submits > 0,
        has_login_data=total_student_logins > 0,
        all_students=all_students,
        logs=logs,
        records=records,
        live_exams=live_exams,
        question_bank_rows=qb_rows,
        notifications=notifications,
        announcements=announcements,
        filters=filters,
        filter_options=filter_options,
        exam_settings=exam_settings
    )


@app.route('/admin/live_exams')
def admin_live_exams():
    if session.get('role') != 'admin':
        return jsonify({"status": "error"}), 403
    return jsonify({"status": "success", "live_exams": sorted(ACTIVE_EXAMS.values(), key=lambda item: item.get("last_seen", ""), reverse=True)})


@app.route('/admin/announce', methods=['POST'])
def admin_announce():
    if session.get('role') != 'admin':
        return jsonify({"status": "error"}), 403

    payload = request.get_json(silent=True) or {}
    message = str(payload.get("message", "")).strip()
    student_id = str(payload.get("student_id", "")).strip().upper()

    if not message:
        return jsonify({"status": "error", "message": "Announcement message is required."}), 400
    if len(message) > 220:
        return jsonify({"status": "error", "message": "Announcement is too long."}), 400

    audience = "broadcast"
    target_sids = []
    if student_id:
        audience = "individual"
        target_sids = list(STUDENT_SIDS.get(student_id, set()))
    else:
        for sid_set in STUDENT_SIDS.values():
            target_sids.extend(list(sid_set))

    created_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with get_db_connection() as conn:
        conn.execute("""
            INSERT INTO announcements (student_id, audience, message, created_at, created_by)
            VALUES (?, ?, ?, ?, ?)
        """, (student_id or "", audience, message, created_at, session.get("user_id", "ADMIN")))
        conn.commit()

    announcement_payload = {
        "student_id": student_id,
        "audience": audience,
        "message": message,
        "created_at": created_at
    }
    for sid in set(target_sids):
        socketio.emit('admin_announcement', announcement_payload, room=sid)

    return jsonify({
        "status": "success",
        "delivered": len(set(target_sids)),
        "created_at": created_at
    })


@app.route('/admin/exam_settings', methods=['POST'])
def update_exam_settings():
    if session.get('role') != 'admin':
        return jsonify({"status": "error"}), 403
    try:
        one_attempt_only = 1 if request.form.get('one_attempt_only') == 'on' else 0
        retake_allowed = 1 if request.form.get('retake_allowed') == 'on' else 0
        max_attempts = min(20, max(1, int(request.form.get('max_attempts', 1) or 1)))
        cooldown_minutes = min(10080, max(0, int(request.form.get('cooldown_minutes', 0) or 0)))
        face_match_threshold = min(0.99, max(0.1, float(request.form.get('face_match_threshold', 0.72) or 0.72)))
        exam_duration_minutes = min(300, max(10, int(request.form.get('exam_duration_minutes', 60) or 60)))
    except ValueError:
        return jsonify({"status": "error", "message": "Exam settings must contain valid numbers."}), 400
    with get_db_connection() as conn:
        conn.execute("""
            UPDATE exam_settings
            SET one_attempt_only=?, retake_allowed=?, max_attempts=?, cooldown_minutes=?,
                face_match_threshold=?, exam_duration_minutes=?
            WHERE id=1
        """, (one_attempt_only, retake_allowed, max_attempts, cooldown_minutes, face_match_threshold, exam_duration_minutes))
        conn.commit()
    return redirect(url_for('admin_dashboard'))


@app.route('/admin/question_bank', methods=['POST'])
def add_question_bank_entry():
    if session.get('role') != 'admin':
        return jsonify({"status": "error"}), 403
    try:
        year_group = int(request.form.get('year_group', 1))
    except (TypeError, ValueError):
        return jsonify({"status": "error", "message": "Invalid year group."}), 400
    section_key = request.form.get('section_key', 'section_a')
    topic = request.form.get('topic', '').strip() or 'General'
    difficulty = request.form.get('difficulty', '').strip() or 'medium'
    question_text = request.form.get('question_text', '').strip()
    answer_text = request.form.get('answer_text', '').strip()
    explanation = request.form.get('explanation', '').strip()
    raw_options = request.form.get('options', '').strip()
    if year_group not in {1, 2, 3, 4} or section_key not in SECTION_ORDER:
        return jsonify({"status": "error", "message": "Invalid question bank section."}), 400
    if not question_text or not answer_text:
        return jsonify({"status": "error", "message": "Question and answer are required."}), 400
    options = [item.strip() for item in raw_options.split('|') if item.strip()]
    with get_db_connection() as conn:
        conn.execute("""
            INSERT INTO question_bank_entries
            (year_group, section_key, topic, difficulty, question_text, options_json, answer_text, explanation)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (year_group, section_key, topic, difficulty, question_text, json.dumps(options), answer_text, explanation))
        conn.commit()
    return redirect(url_for('admin_dashboard') + "#question-bank")


@app.route('/admin/question_bank/<int:entry_id>/delete', methods=['POST'])
def delete_question_bank_entry(entry_id):
    if session.get('role') != 'admin':
        return jsonify({"status": "error"}), 403
    with get_db_connection() as conn:
        conn.execute("DELETE FROM question_bank_entries WHERE id=?", (entry_id,))
        conn.commit()
    return jsonify({"status": "success"})


@app.route('/admin/result/<int:result_id>/decision', methods=['POST'])
def update_result_decision(result_id):
    if session.get('role') != 'admin':
        return jsonify({"status": "error"}), 403
    payload = request.get_json(silent=True) or {}
    decision = payload.get("decision", "pending")
    notes = payload.get("notes", "")
    if decision not in {"clean", "warning", "malpractice_confirmed", "pending"}:
        return jsonify({"status": "error", "message": "Invalid decision"}), 400
    with get_db_connection() as conn:
        conn.execute("UPDATE results SET admin_decision=?, decision_notes=? WHERE id=?", (decision, notes, result_id))
        conn.commit()
    return jsonify({"status": "success", "decision": decision})


@app.route('/verify_face', methods=['POST'])
def verify_face():
    try:
        if session.get('role') != 'student':
            return jsonify({"status": "error", "message": "Unauthorized access."}), 403

        payload = request.get_json(silent=True) or {}
        live_image = payload.get("image")
        if not live_image:
            return jsonify({"status": "error", "message": "Camera frame not received. Please try again."}), 400

        with get_db_connection() as conn:
            user = conn.execute("SELECT profile_pic FROM users WHERE id=?", (session['user_id'],)).fetchone()

        if not user or not user["profile_pic"]:
            return jsonify({"status": "error", "message": "Profile image not found."}), 400

        profile_path = os.path.join(app.config['UPLOAD_FOLDER'], user["profile_pic"])
        if user["profile_pic"] == "default.png" or not os.path.exists(profile_path):
            return jsonify({
                "status": "error",
                "message": "Please upload your profile photo in the student dashboard before verifying your face."
            }), 400

        score = float(compute_face_match_score(profile_path, live_image))
        threshold = float(get_exam_settings().get("face_match_threshold", 0.72))
        passed = bool(score >= threshold)
        refresh_live_exam(session['user_id'], face_verified=passed, face_match_score=score)
        return jsonify({
            "status": "success",
            "passed": passed,
            "score": float(score),
            "threshold": float(threshold)
        })
    except Exception as exc:
        app.logger.exception("Face verification failed")
        return jsonify({
            "status": "error",
            "message": f"Face verification crashed on the server: {str(exc)}"
        }), 500


@app.route('/student/result/<int:result_id>/pdf')
def download_student_result_pdf(result_id):
    if session.get('role') != 'student':
        return redirect(url_for('login'))
    with get_db_connection() as conn:
        row = conn.execute("""
            SELECT score, total, date, year_group, analysis_json, risk_score, risk_level, admin_decision
            FROM results
            WHERE id=? AND student_id=?
        """, (result_id, session['user_id'])).fetchone()
    if not row:
        abort(404)
    sections = [
        ("Result Summary", [
            f"Student ID: {session['user_id']}",
            f"Student Name: {session['name']}",
            f"Year Exam: {row['year_group']}",
            f"Score: {row['score']} / {row['total']}",
            f"Submitted At: {row['date']}",
            f"Risk Score: {row['risk_score']} ({row['risk_level']})",
            f"Admin Decision: {row['admin_decision']}",
        ])
    ]
    try:
        analysis = json.loads(row["analysis_json"] or "{}")
    except json.JSONDecodeError:
        analysis = {}
    for section in analysis.get("section_results", []):
        sections.append((section.get("title", "Section"), [f"Score: {section.get('score')} / {section.get('total')}"]))
    pdf = build_pdf_document("Student Result Report", sections)
    return send_file(pdf, as_attachment=True, download_name=f"{session['user_id']}_result_{result_id}.pdf", mimetype='application/pdf')


@app.route('/admin/export/<string:export_format>')
def export_admin_data(export_format):
    if session.get('role') != 'admin':
        return redirect(url_for('login'))
    filters = {
        "branch": request.args.get("branch", "").strip(),
        "semester": request.args.get("semester", "").strip(),
        "date": request.args.get("date", "").strip(),
        "year_group": request.args.get("year_group", "").strip(),
    }
    record_filters = []
    record_params = []
    if filters["branch"]:
        record_filters.append("u.branch=?")
        record_params.append(filters["branch"])
    if filters["semester"]:
        record_filters.append("u.semester=?")
        record_params.append(filters["semester"])
    if filters["date"]:
        record_filters.append("SUBSTR(r.date, 1, 10)=?")
        record_params.append(filters["date"])
    if filters["year_group"]:
        record_filters.append("r.year_group=?")
        record_params.append(filters["year_group"])
    violation_filters = []
    violation_params = []
    if filters["branch"]:
        violation_filters.append("u.branch=?")
        violation_params.append(filters["branch"])
    if filters["semester"]:
        violation_filters.append("u.semester=?")
        violation_params.append(filters["semester"])
    if filters["date"]:
        violation_filters.append("SUBSTR(v.created_at, 1, 10)=?")
        violation_params.append(filters["date"])
    record_where = ("WHERE " + " AND ".join(record_filters)) if record_filters else ""
    violation_where = ("WHERE " + " AND ".join(violation_filters)) if violation_filters else ""
    with get_db_connection() as conn:
        records = conn.execute(f"""
            SELECT r.student_id, u.name, u.branch, u.semester, r.score, r.total, r.date, r.year_group, r.risk_score, r.risk_level, r.admin_decision
            FROM results r
            JOIN users u ON r.student_id = u.id
            {record_where}
            ORDER BY r.id DESC
        """, record_params).fetchall()
        logs = conn.execute(f"""
            SELECT v.student_id, u.name, v.type, v.severity, v.score, v.created_at, v.evidence_path
            FROM violations v
            JOIN users u ON v.student_id = u.id
            {violation_where}
            ORDER BY v.id DESC
            LIMIT 100
        """, violation_params).fetchall()

    if export_format == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["student_id", "name", "branch", "semester", "score", "total", "date", "year_group", "risk_score", "risk_level", "admin_decision"])
        for row in records:
            writer.writerow(list(row))
        response = make_response(output.getvalue())
        response.headers["Content-Disposition"] = "attachment; filename=admin_records.csv"
        response.headers["Content-Type"] = "text/csv"
        return response

    if export_format == "pdf":
        record_lines = [f"{row['student_id']} | {row['name']} | {row['score']}/{row['total']} | Year {row['year_group']} | Risk {row['risk_level']}" for row in records[:40]]
        violation_lines = [f"{row['student_id']} | {row['type']} | {row['severity']} | {row['created_at']}" for row in logs[:30]]
        proof_images = [
            os.path.join("static", row["evidence_path"].replace("/", os.sep))
            for row in logs if row["evidence_path"]
        ][:6]
        pdf = build_pdf_document("Admin Proctoring Report", [("Exam Results", record_lines), ("Violation Summary", violation_lines)], proof_images)
        return send_file(pdf, as_attachment=True, download_name="admin_report.pdf", mimetype='application/pdf')

    abort(404)

@app.route('/admin/delete_student/<sid>', methods=['POST'])
def delete_student(sid):
    if session.get('role') != 'admin': return jsonify({"status": "error"}), 403
    try:
        with get_db_connection() as conn:
            proof_rows = conn.execute(
                "SELECT evidence_path FROM violations WHERE student_id=?",
                (sid,)
            ).fetchall()
            conn.execute("DELETE FROM users WHERE id=?", (sid,))
            conn.execute("DELETE FROM results WHERE student_id=?", (sid,))
            conn.execute("DELETE FROM violations WHERE student_id=?", (sid,))
            conn.execute("DELETE FROM login_activity WHERE user_id=?", (sid,))
            conn.commit()
        for proof_row in proof_rows:
            remove_violation_proof(proof_row[0])
        return jsonify({"status": "success"})
    except:
        return jsonify({"status": "error"}), 500

@app.route('/admin/clear_logs', methods=['POST'])
def clear_logs():
    if session.get('role') != 'admin': return jsonify({"status": "error"}), 403
    with get_db_connection() as conn:
        proof_rows = conn.execute("SELECT evidence_path FROM violations").fetchall()
        conn.execute("DELETE FROM violations")
        conn.commit()
    for proof_row in proof_rows:
        remove_violation_proof(proof_row[0])
    return jsonify({"status": "success"})

@app.route('/submit_exam', methods=['POST'])
def submit_exam():
    try:
        app.logger.info(
            "submit_exam called user=%s role=%s content_length=%s content_type=%s",
            session.get('user_id'),
            session.get('role'),
            request.content_length,
            request.content_type,
        )
        if session.get('role') != 'student':
            app.logger.warning("submit_exam rejected: not a student user=%s", session.get('user_id'))
            return jsonify({"status": "error"}), 403

        data = request.get_json(silent=True) or {}
        year_group = data.get('year_group')
        answers = data.get('answers', {})
        app.logger.info(
            "submit_exam payload user=%s year_group=%s answer_count=%s",
            session.get('user_id'),
            year_group,
            len(answers) if isinstance(answers, dict) else 'n/a',
        )

        try:
            year_group = int(year_group)
        except (TypeError, ValueError):
            app.logger.warning("submit_exam rejected: invalid year group user=%s raw=%s", session.get('user_id'), year_group)
            return jsonify({"status": "error", "message": "Invalid year group."}), 400

        allowed_group = get_student_year_group(session['user_id'])
        if year_group != allowed_group:
            app.logger.warning(
                "submit_exam rejected: unauthorized access user=%s allowed=%s requested=%s",
                session.get('user_id'),
                allowed_group,
                year_group,
            )
            return jsonify({"status": "error", "message": "Unauthorized exam access."}), 403

        attempt_summary = get_attempt_summary(session['user_id'], year_group)
        if not attempt_summary["allowed"]:
            app.logger.warning(
                "submit_exam rejected: attempt limit user=%s year_group=%s reason=%s",
                session.get('user_id'),
                year_group,
                attempt_summary["reason"],
            )
            return jsonify({"status": "error", "message": attempt_summary["reason"]}), 400

        try:
            result = grade_exam_with_bank(year_group, session['user_id'], answers)
        except ValueError:
            app.logger.exception("submit_exam failed: exam paper missing user=%s year_group=%s", session.get('user_id'), year_group)
            return jsonify({"status": "error", "message": "Exam paper not found."}), 404

        section_scores_json = json.dumps([
            {
                "id": section["id"],
                "title": section["title"],
                "score": section["score"],
                "total": section["total"]
            }
            for section in result["section_results"]
        ], default=json_default)
        current_exam = ACTIVE_EXAMS.get(session['user_id'], {})
        exam_started_at = current_exam.get("exam_started_at")
        since_time = parse_timestamp(exam_started_at) if exam_started_at else datetime.now() - timedelta(hours=2)
        risk_score, risk_level = compute_risk_for_student(session['user_id'], since_time)
        attempt_number = attempt_summary["attempts_used"] + 1
        result["risk_score"] = risk_score
        result["risk_level"] = risk_level
        result["attempt_number"] = attempt_number
        analysis_json = json.dumps(result, default=json_default)

        try:
            with get_db_connection() as conn:
                conn.execute("""
                    INSERT INTO results (student_id, score, total, violations, date, year_group, section_scores, analysis_json, risk_score, risk_level, attempt_number, admin_decision)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    session['user_id'],
                    result['total_score'],
                    result['total_marks'],
                    "Check Logs",
                    datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                    year_group,
                    section_scores_json,
                    analysis_json,
                    risk_score,
                    risk_level,
                    attempt_number,
                    "pending"
                ))
                conn.commit()
            ACTIVE_EXAMS.pop(session['user_id'], None)
        except sqlite3.OperationalError as error:
            app.logger.exception("Failed to save exam submission for %s", session.get('user_id'))
            return jsonify({"status": "error", "message": f"Could not save the exam result: {error}"}), 500

        app.logger.info(
            "submit_exam success user=%s score=%s/%s risk=%s/%s",
            session.get('user_id'),
            result.get('total_score'),
            result.get('total_marks'),
            result.get('risk_score'),
            result.get('risk_level'),
        )
        return jsonify({"status": "success", "result": json.loads(analysis_json)})
    except Exception as error:
        app.logger.exception("Unexpected failure while submitting exam for %s", session.get("user_id"))
        return jsonify({"status": "error", "message": f"Could not submit the exam right now: {error}"}), 500

@app.route('/exam/<int:group>')
def exam(group):
    if session.get('role') != 'student': return redirect(url_for('login'))
    allowed_group = get_student_year_group(session['user_id'])
    if group != allowed_group:
        return redirect(url_for('student_dashboard'))
    attempt_summary = get_attempt_summary(session['user_id'], group)
    if not attempt_summary["allowed"]:
        return redirect(url_for('student_dashboard'))
    if not get_managed_question_bank(group):
        abort(404)

    exam_payload = build_exam_with_bank(group, session['user_id'])
    settings = get_exam_settings()
    existing_exam = ACTIVE_EXAMS.get(session['user_id'], {})
    resume_state = {
        "remaining_seconds": int(existing_exam.get("remaining_seconds", 0) or 0),
        "violation_count": int(existing_exam.get("violation_count", 0) or 0),
        "violation_score_total": int(existing_exam.get("violation_score_total", 0) or 0),
        "risk_score": float(existing_exam.get("risk_score", 0) or 0),
        "risk_level": existing_exam.get("risk_level", "Low"),
        "latest_violation": existing_exam.get("latest_violation", ""),
        "face_verified": bool(existing_exam.get("face_verified")),
        "face_match_score": float(existing_exam.get("face_match_score", 0) or 0),
        "mic_status": existing_exam.get("mic_status", "normal"),
        "exam_started_at": existing_exam.get("exam_started_at", ""),
        "active": bool(existing_exam),
    }
    exam_view = {
        "paper_title": exam_payload["paper_title"],
        "sections": []
    }

    for section in exam_payload["sections"]:
        exam_view["sections"].append({
            "id": section["id"],
            "title": section["title"],
            "question_type": section["question_type"],
            "marks_per_question": section["marks_per_question"],
            "questions": [
                {
                    "id": question["id"],
                    "question": question["question"],
                    "options": question.get("options", []),
                    "type": question["type"],
                    "marks": question["marks"]
                }
                for question in section["questions"]
            ]
        })

    refresh_live_exam(
        session['user_id'],
        student_name=session.get('name', ''),
        year_group=group,
        violation_count=int(existing_exam.get("violation_count", 0) or 0),
        violation_score_total=int(existing_exam.get("violation_score_total", 0) or 0),
        risk_score=float(existing_exam.get("risk_score", 0) or 0),
        risk_level=existing_exam.get("risk_level", "Low"),
        latest_violation=existing_exam.get("latest_violation", ""),
        current_frame="",
        mic_status=existing_exam.get("mic_status", "normal"),
        face_verified=bool(existing_exam.get("face_verified")),
        face_match_score=float(existing_exam.get("face_match_score", 0) or 0),
        exam_started_at=existing_exam.get("exam_started_at") or datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    )

    return render_template(
        'exam_structured.html',
        student_name=session['name'],
        student_id=session['user_id'],
        year_group=group,
        exam_payload=exam_view,
        exam_settings=settings,
        attempt_summary=attempt_summary,
        resume_state=resume_state
    )

@app.route('/logout')
def logout():
    ACTIVE_EXAMS.pop(session.get('user_id'), None)
    session.clear()
    return redirect(url_for('login'))

# --- AI SOCKET LOGIC ---
@socketio.on('connect')
def handle_connect():
    if session.get('role') == 'admin':
        ADMIN_SIDS.add(request.sid)
    elif session.get('role') == 'student' and session.get('user_id'):
        STUDENT_SIDS.setdefault(session['user_id'], set()).add(request.sid)


@socketio.on('disconnect')
def handle_disconnect():
    ADMIN_SIDS.discard(request.sid)
    for student_id, sid_set in list(STUDENT_SIDS.items()):
        sid_set.discard(request.sid)
        if not sid_set:
            STUDENT_SIDS.pop(student_id, None)


@socketio.on('exam_status')
def handle_exam_status(data):
    sid = get_socket_student_id()
    if not sid:
        return
    refresh_live_exam(
        sid,
        student_name=data.get('student_name', ''),
        year_group=data.get('year_group'),
        remaining_seconds=int(data.get('remaining_seconds', 0) or 0),
        current_frame=data.get('frame', ''),
        mic_status=data.get('mic_status', 'unknown'),
        face_verified=bool(data.get('face_verified')),
        face_match_score=data.get('face_match_score', 0),
        violation_count=int(data.get('violation_count', 0) or 0),
        violation_score_total=int(data.get('violation_score_total', 0) or 0)
    )


@socketio.on('video_frame')
def handle_frame(data):
    sid = get_socket_student_id()
    if not sid:
        return
    model = get_model()
    try:
        header, encoded = data['image'].split(",", 1)
        nparr = np.frombuffer(base64.b64decode(encoded), np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if frame is None:
            app.logger.warning("Unable to decode video frame for student %s", sid)
            return
        h, w, _ = frame.shape
        if w > DETECTION_FRAME_WIDTH:
            scale = DETECTION_FRAME_WIDTH / float(w)
            frame = cv2.resize(frame, (DETECTION_FRAME_WIDTH, max(1, int(h * scale))))
        h, w, _ = frame.shape
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        face_detector = get_face_detector()
        faces = []
        if face_detector is not None and not face_detector.empty():
            faces = face_detector.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(50, 50))
        face_count = len(faces)
        results = None
        if model is not None:
            tracked_labels = {'person', *FORBIDDEN_OBJECTS}
            tracked_classes = [index for index, label in model.names.items() if label in tracked_labels]
            results = model(
                frame,
                verbose=False,
                classes=tracked_classes,
                conf=0.16,
                imgsz=min(640, DETECTION_FRAME_WIDTH),
                max_det=8,
            )[0]
        alerts, people = [], 0
        current = ACTIVE_EXAMS.get(sid, {})
        now = datetime.now()
        if results is not None and getattr(results, "boxes", None) is not None:
            for box in results.boxes:
                label = model.names[int(box.cls[0])]
                if label == 'person':
                    people += 1
                    x1, _, x2, _ = box.xyxy[0].tolist()
                    center_x = (x1 + x2) / 2
                    looking_key = None
                    if center_x < (w * 0.25):
                        looking_key = "looking_left"
                        alert_text = "Looking Away (Left)"
                    elif center_x > (w * 0.75):
                        looking_key = "looking_right"
                        alert_text = "Looking Away (Right)"
                    if looking_key:
                        last_seen = parse_timestamp(current.get(f"{looking_key}_at"))
                        if not last_seen or (now - last_seen).total_seconds() >= 4:
                            alerts.append(alert_text)
                            current[f"{looking_key}_at"] = now.strftime("%Y-%m-%d %H:%M:%S")
                if label in FORBIDDEN_OBJECTS:
                    object_key = f"object_{label.replace(' ', '_')}_at"
                    last_seen = parse_timestamp(current.get(object_key))
                    if not last_seen or (now - last_seen).total_seconds() >= 5:
                        alerts.append(f"Detected: {label}")
                        current[object_key] = now.strftime("%Y-%m-%d %H:%M:%S")
        if people > 1 or face_count > 1:
            last_multiple = parse_timestamp(current.get("multiple_faces_at"))
            if not last_multiple or (now - last_multiple).total_seconds() >= 5:
                alerts.append("Multiple People")
                current["multiple_faces_at"] = now.strftime("%Y-%m-%d %H:%M:%S")
            current["no_face_started_at"] = ""
            current["no_face_logged"] = False
        elif face_count == 0:
            no_face_started_at = parse_timestamp(current.get("no_face_started_at"))
            if not no_face_started_at:
                current["no_face_started_at"] = now.strftime("%Y-%m-%d %H:%M:%S")
                current["no_face_logged"] = False
            else:
                elapsed = (now - no_face_started_at).total_seconds()
                if elapsed >= 5 and not bool(current.get("no_face_logged")):
                    alerts.append("No Face Detected > 5 Seconds")
                    current["no_face_logged"] = True
        else:
            current["no_face_started_at"] = ""
            current["no_face_logged"] = False
        
        if alerts:
            unique_alerts = list(dict.fromkeys(alerts))
            payload_alerts = []
            for alert in unique_alerts:
                payload_alerts.append(create_violation_record(sid, alert, data.get('image')))
            emit('cheat_alert', {'alerts': payload_alerts}, room=request.sid)
        else:
            refresh_live_exam(sid, current_frame=data.get('image'))
        ACTIVE_EXAMS[sid] = {**ACTIVE_EXAMS.get(sid, {}), **current}
    except Exception:
        app.logger.exception("Failed to process video frame for student %s", sid)

@socketio.on('audio_violation')
def handle_audio(data):
    sid = get_socket_student_id()
    if not sid:
        return
    alert_payload = create_violation_record(
        sid,
        "Loud Noise Detected",
        data.get('evidence_image')
    )
    refresh_live_exam(sid, mic_status="noise")
    emit('cheat_alert', {'alerts': [alert_payload]}, room=request.sid)

@socketio.on('tab_switch')
def handle_tab_switch(data):
    sid = get_socket_student_id()
    if not sid:
        return
    reason = data.get('msg', "Tab Switch / Focus Lost")
    alert_payload = create_violation_record(
        sid,
        reason,
        data.get('evidence_image')
    )
    emit('cheat_alert', {'alerts': [alert_payload]}, room=request.sid)

if __name__ == '__main__':
    socketio.run(app, debug=RUN_DEBUG, host=RUN_HOST, port=RUN_PORT)
