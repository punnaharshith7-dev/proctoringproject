# ProctorX

This project is now set up as a deployable Flask website.

## Run locally

```bash
python app.py
```

Open `http://127.0.0.1:5000` in Chrome. Camera and microphone access works on localhost; use HTTPS after deployment.

## Interview Demo Flow

1. Register a student with a profile image, then log in to show the student performance dashboard.
2. Start the unlocked assessment, enable media, verify the face, and show the responsive readiness checklist.
3. Submit an attempt to demonstrate section-wise scoring, risk calculation, recommendations, and downloadable PDF reporting.
4. Sign in as the admin to show live monitoring, violation evidence, announcements, question-bank management, analytics, and CSV/PDF exports.

## Technical Highlights

- Flask and Socket.IO provide role-based dashboards and real-time proctoring updates.
- OpenCV face detection and YOLO object detection contribute monitored violation signals.
- SQLite stores students, attempts, question banks, audit records, notifications, and configuration.
- The assessment recovers local answer state after a refresh and limits attempts server-side.

## Deployment Settings

Set `SECRET_KEY` to a long random value in production. Optionally set `SESSION_COOKIE_SECURE=true` on HTTPS deployments. Socket connections are same-origin by default; set `SOCKETIO_CORS_ORIGINS` only when a separate frontend origin is required.

## Google Sign-In

Create a Google OAuth client of type **Web application**, then configure these environment variables: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and `GOOGLE_REDIRECT_URI`.

For local development, add `http://127.0.0.1:5000/auth/google/callback` as an authorized redirect URI. For production, use the exact HTTPS callback URL served by your deployment. Google-authenticated users are created as students and must still add their profile details and photo before they can pass face verification for an exam.

Use [.env.example](./.env.example) as the non-secret configuration reference. In Google Cloud, register `http://127.0.0.1:5000` as the local authorized JavaScript origin and `http://127.0.0.1:5000/auth/google/callback` as the local authorized redirect URI.

## Deploy to get a public link

The repo includes `render.yaml` and a `Procfile` so you can deploy it on Render or a similar host.

Set these environment variables in the hosting dashboard before publishing:

- `SECRET_KEY`
- `ADMIN_INITIAL_PASSWORD` if you want the app to bootstrap a fresh admin account

The app needs HTTPS for camera and microphone access in the browser, so a hosted deployment is the right path for sharing it by link.
