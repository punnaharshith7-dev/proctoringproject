<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Overwatch | Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='tilt-effects.css') }}">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-dialog.css') }}">
    <script src="{{ url_for('static', filename='tilt-effects.js') }}" defer></script>
    <script src="{{ url_for('static', filename='proctorx-dialog.js') }}" defer></script>
    <style>
        :root { --primary: #23a6d5; --danger: #e73c7e; --dark: #1a1a2e; --sidebar: #1e1e2f; }
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        body { background: #f4f7f6; display: flex; min-height: 100vh; }

        /* Sidebar */
        #side-nav { width: 280px; background: var(--sidebar); color: white; padding: 30px 20px; display: flex; flex-direction: column; position: fixed; height: 100vh; }
        .nav-brand { font-size: 1.5rem; font-weight: 600; margin-bottom: 40px; }
        .nav-link { padding: 15px; color: #aaa; text-decoration: none; border-radius: 10px; cursor: pointer; margin-bottom: 10px; display: block; }
        .nav-link:hover, .nav-link.active { background: rgba(255,255,255,0.1); color: white; }
        
        /* Layout */
        #content { margin-left: 280px; flex: 1; padding: 40px; }
        .section { display: none; }
        .section.active { display: block; }
        
        /* Stats */
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: white; padding: 25px; border-radius: 20px; box-shadow: 0 5px 15px rgba(0,0,0,0.05); text-align: center; }
        
        /* Year-wise Submissions Grid */
        .year-stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-top: 20px; }
        .year-card { background: #f8faff; padding: 15px; border-radius: 12px; border: 1px solid #edf2f7; text-align: center; }
        .year-label { font-size: 0.75rem; color: #888; text-transform: uppercase; font-weight: 600; }
        .year-value { font-size: 1.5rem; color: var(--primary); font-weight: 600; }

        /* Tables */
        .panel { background: white; padding: 30px; border-radius: 25px; box-shadow: 0 10px 30px rgba(0,0,0,0.05); margin-bottom: 30px; }
        table { width: 100%; border-collapse: collapse; }
        th { text-align: left; padding: 15px; border-bottom: 2px solid #f0f0f0; color: #888; font-size: 0.8rem; }
        td { padding: 15px; border-bottom: 1px solid #f9f9f9; font-size: 0.9rem; vertical-align: middle; }
        
        .badge { padding: 5px 12px; border-radius: 50px; font-weight: 600; font-size: 0.75rem; }
        .badge-danger { background: #ffe0e0; color: var(--danger); }
        .badge-info { background: #e0f0ff; color: var(--primary); }
        
        .student-pic { width: 45px; height: 45px; border-radius: 50%; object-fit: cover; border: 2px solid #eee; }

        /* Actions */
        .btn-del { color: var(--danger); border: 1px solid var(--danger); padding: 6px 12px; border-radius: 8px; cursor: pointer; background: transparent; font-size: 0.75rem; font-weight: 600; transition: 0.3s; }
        .btn-del:hover { background: var(--danger); color: white; }
        .btn-clear { background: var(--danger); color: white; padding: 10px 20px; border: none; border-radius: 8px; cursor: pointer; }
        input { padding: 10px; border-radius: 8px; border: 1px solid #ddd; width: 300px; }
    </style>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body>

    <div id="side-nav">
        <div class="nav-brand">🛡️ Overwatch</div>
        <div class="nav-link active" onclick="showSection('dashboard', this)">Dashboard</div>
        <div class="nav-link" onclick="showSection('proctoring', this)">Live Proctoring</div>
        <div class="nav-link" onclick="showSection('profiles', this)">Student Profiles</div> 
        <div class="nav-link" onclick="showSection('records', this)">Examination Records</div>
        <div class="nav-link" onclick="showSection('settings', this)">System Settings</div>
        <a href="/logout" style="margin-top:auto; color:var(--danger); text-decoration:none;">Logout</a>
    </div>

    <div id="content">
        <div id="dashboard" class="section active">
            <h1>Summary Dashboard</h1>
            <div class="stats-grid">
                <div class="stat-card"><h3>Exams Submitted</h3><p style="font-size:2.5rem; color:var(--primary);">{{ submissions }}</p></div>
                <div class="stat-card"><h3>Violations Detected</h3><p style="font-size:2.5rem; color:var(--danger);">{{ violation_count }}</p></div>
            </div>

            <div class="panel">
                <h3>Year-wise Submissions</h3>
                <div class="year-stats-grid">
                    {% for year, count in year_stats.items() %}
                    <div class="year-card">
                        <div class="year-label">Year {{ year }}</div>
                        <div class="year-value">{{ count }}</div>
                    </div>
                    {% endfor %}
                </div>
            </div>
        </div>

        <div id="proctoring" class="section">
            <h1>Live Violation Data</h1>
            <div class="panel">
                <table>
                    <thead><tr><th>ID</th><th>Name</th><th>Violation</th><th>Time</th></tr></thead>
                    <tbody>
                        {% for log in logs %}
                        <tr><td>{{ log[0] }}</td><td>{{ log[1] }}</td><td><span class="badge badge-danger">{{ log[2] }}</span></td><td>{{ log[3] }}</td></tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>

        <div id="profiles" class="section">
            <h1>Registered Student Details</h1>
            <div class="panel">
                <table>
                    <thead>
                        <tr>
                            <th>Photo</th>
                            <th>Roll Number</th>
                            <th>Name</th>
                            <th>Branch</th>
                            <th>Semester</th>
                            <th>Phone</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for s in all_students %}
                        <tr id="student-{{ s[0] }}">
                            <td><img src="{{ url_for('static', filename='profiles/' + s[5]) }}" class="student-pic"></td>
                            <td><span class="badge badge-info">{{ s[0] }}</span></td>
                            <td><strong>{{ s[1] }}</strong></td>
                            <td>{{ s[2] }}</td>
                            <td>{{ s[3] }}</td>
                            <td>{{ s[4] }}</td>
                            <td><button class="btn-del" onclick="deleteStudent('{{ s[0] }}')">Delete Profile</button></td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>

        <div id="records" class="section">
            <h1>Examination Records</h1>
            <div class="panel">
                <table>
                    <thead><tr><th>Roll Number</th><th>Name</th><th>Marks Got</th><th>Submission Time</th></tr></thead>
                    <tbody>
                        {% for r in records %}
                        <tr><td>{{ r[0] }}</td><td>{{ r[1] }}</td><td><strong>{{ r[2] }} / {{ r[3] }}</strong></td><td>{{ r[4] }}</td></tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>

        <div id="settings" class="section">
            <h1>System Settings</h1>
            <div class="panel" style="margin-bottom: 20px;">
                <h3>Search Student Info</h3>
                <input type="text" id="searchRoll" placeholder="Enter Roll Number">
                <button class="btn-clear" style="background:var(--primary)" onclick="proctorxAlert('Enter a roll number and use the student profiles directory to locate a record.', { type: 'info', title: 'Student search' })">Search</button>
            </div>
            <div class="panel">
                <h3>Data Management</h3>
                <p style="color:#888; margin-bottom:15px;">This action will permanently delete all recorded violations from the database.</p>
                <button class="btn-clear" onclick="clearLogs()">Clear All Violation Logs</button>
            </div>
        </div>
    </div>

    <script>
        function showSection(id, btn) {
            document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
            document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
            document.getElementById(id).classList.add('active');
            btn.classList.add('active');
        }

        async function deleteStudent(sid) {
            if(await proctorxConfirm('This permanently deletes the student profile, exam records, and violation evidence.', { type: 'danger', title: 'Delete student profile', confirmText: 'Delete permanently' })) {
                const res = await fetch(`/admin/delete_student/${sid}`, { method: 'POST' });
                const data = await res.json();
                if(data.status === 'success') {
                    document.getElementById(`student-${sid}`).remove();
                    await proctorxAlert('The student profile and linked records were removed.', { type: 'success', title: 'Profile deleted' });
                } else {
                    await proctorxAlert('The profile could not be deleted. Please try again.', { type: 'danger', title: 'Delete failed' });
                }
            }
        }

        async function clearLogs() {
            if(await proctorxConfirm('This permanently removes all saved violation logs and their evidence images.', { type: 'danger', title: 'Clear violation logs', confirmText: 'Clear logs' })) {
                fetch('/admin/clear_logs', { method: 'POST' })
                .then(() => location.reload());
            }
        }
    </script>

<button class="proctorx-fab" type="button" aria-label="Help" onclick="alert('Support center coming soon!')">
    <svg viewBox="0 0 24 24" aria-hidden="true" fill="currentColor">
        <path d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z"/>
    </svg>
</button>

</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Overwatch | Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='tilt-effects.css') }}">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-dialog.css') }}">
    <script src="{{ url_for('static', filename='tilt-effects.js') }}" defer></script>
    <script src="{{ url_for('static', filename='proctorx-dialog.js') }}" defer></script>
    <style>
        :root {
            --bg: #f3f7fb;
            --panel: rgba(255, 255, 255, 0.88);
            --panel-border: rgba(137, 160, 188, 0.22);
            --text: #142033;
            --muted: #66768d;
            --primary: #1f7ae0;
            --teal: #1aa7a1;
            --gold: #f4a900;
            --danger: #df4d6a;
            --sidebar: #102038;
            --shadow: 0 20px 45px rgba(15, 32, 56, 0.12);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            min-height: 100vh;
            display: flex;
            background:
                radial-gradient(circle at top left, rgba(31, 122, 224, 0.16), transparent 28%),
                radial-gradient(circle at bottom right, rgba(26, 167, 161, 0.12), transparent 24%),
                var(--bg);
            color: var(--text);
            font-family: 'Plus Jakarta Sans', sans-serif;
            overflow: hidden;
        }

        #side-nav {
            width: 290px;
            min-width: 290px;
            background: linear-gradient(180deg, #12233d 0%, #0d182b 100%);
            color: white;
            padding: 28px 20px;
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0;
            left: 0;
            bottom: 0;
            height: 100vh;
            box-shadow: 18px 0 40px rgba(13, 24, 43, 0.18);
            overflow-y: auto;
            overflow-x: hidden;
            scrollbar-gutter: stable;
        }

        .nav-brand {
            font-family: 'Space Grotesk', sans-serif;
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .nav-copy {
            color: rgba(255, 255, 255, 0.7);
            font-size: 0.92rem;
            line-height: 1.6;
            margin-bottom: 28px;
        }

        .nav-link {
            padding: 14px 16px;
            color: rgba(255, 255, 255, 0.72);
            text-decoration: none;
            border-radius: 14px;
            cursor: pointer;
            margin-bottom: 10px;
            display: block;
            transition: 0.25s ease;
            border: 1px solid transparent;
        }

        .nav-link:hover,
        .nav-link.active {
            background: rgba(255, 255, 255, 0.1);
            color: white;
            border-color: rgba(255, 255, 255, 0.1);
        }

        .logout-link {
            margin-top: auto;
            color: #ff9fb5;
            text-decoration: none;
            padding: 14px 16px;
            border-radius: 14px;
            background: rgba(223, 77, 106, 0.08);
        }

        #content {
            margin-left: 290px;
            width: calc(100% - 290px);
            max-width: calc(100% - 290px);
            height: 100vh;
            padding: 34px;
            overflow-y: auto;
            overflow-x: hidden;
        }

        .section {
            display: none;
            animation: fadeIn 0.28s ease;
        }

        .section.active {
            display: block;
        }

        .eyebrow {
            color: var(--primary);
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.12em;
            font-size: 0.75rem;
            margin-bottom: 10px;
        }

        .page-title {
            font-family: 'Space Grotesk', sans-serif;
            font-size: clamp(2rem, 4vw, 2.8rem);
            margin-bottom: 10px;
        }

        .page-subtitle {
            max-width: 760px;
            color: var(--muted);
            line-height: 1.7;
            margin-bottom: 28px;
        }

        .stats-grid,
        .charts-grid {
            display: grid;
            gap: 22px;
            margin-bottom: 24px;
        }

        .stats-grid {
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        }

        .charts-grid {
            grid-template-columns: repeat(auto-fit, minmax(340px, 1fr));
        }

        .stat-card,
        .panel {
            background: var(--panel);
            border: 1px solid var(--panel-border);
            border-radius: 26px;
            box-shadow: var(--shadow);
            backdrop-filter: blur(12px);
        }

        .stat-card {
            padding: 24px;
            position: relative;
            overflow: hidden;
        }

        .stat-card::before {
            content: "";
            position: absolute;
            top: -42px;
            right: -10px;
            width: 110px;
            height: 110px;
            border-radius: 50%;
            background: linear-gradient(135deg, rgba(31, 122, 224, 0.16), rgba(26, 167, 161, 0.06));
        }

        .stat-label {
            font-size: 0.84rem;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--muted);
            margin-bottom: 14px;
        }

        .stat-value {
            font-family: 'Space Grotesk', sans-serif;
            font-size: 2.2rem;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .stat-meta {
            color: var(--muted);
            font-size: 0.92rem;
        }

        .panel {
            padding: 24px;
            margin-bottom: 24px;
        }

        .panel-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            margin-bottom: 18px;
        }

        .panel-head h3 {
            font-family: 'Space Grotesk', sans-serif;
            font-size: 1.2rem;
        }

        .panel-note {
            color: var(--muted);
            font-size: 0.88rem;
        }

        .year-stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 14px;
        }

        .year-card {
            padding: 18px;
            border-radius: 18px;
            background: linear-gradient(180deg, #f8fbff 0%, #eef6ff 100%);
            border: 1px solid rgba(31, 122, 224, 0.12);
        }

        .year-label {
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.08em;
            font-size: 0.75rem;
            margin-bottom: 10px;
        }

        .year-value {
            font-family: 'Space Grotesk', sans-serif;
            color: var(--primary);
            font-size: 1.7rem;
            font-weight: 700;
        }

        .chart-shell {
            position: relative;
            height: 320px;
        }

        .chart-shell canvas {
            width: 100% !important;
            height: 100% !important;
        }

        .empty-state {
            min-height: 220px;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 24px;
            border-radius: 18px;
            border: 1px dashed rgba(102, 118, 141, 0.32);
            color: var(--muted);
            background: rgba(245, 248, 252, 0.9);
            line-height: 1.7;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th,
        td {
            text-align: left;
            padding: 14px 10px;
            border-bottom: 1px solid rgba(137, 160, 188, 0.14);
            font-size: 0.92rem;
            vertical-align: middle;
        }

        th {
            color: var(--muted);
            font-size: 0.78rem;
            text-transform: uppercase;
            letter-spacing: 0.08em;
        }

        tbody tr:hover {
            background: rgba(31, 122, 224, 0.04);
        }

        .badge {
            display: inline-flex;
            align-items: center;
            padding: 6px 12px;
            border-radius: 999px;
            font-weight: 700;
            font-size: 0.74rem;
        }

        .badge-danger {
            background: rgba(223, 77, 106, 0.12);
            color: var(--danger);
        }

        .badge-info {
            background: rgba(31, 122, 224, 0.12);
            color: var(--primary);
        }

        .badge-success {
            background: rgba(26, 167, 161, 0.12);
            color: var(--teal);
        }

        .student-pic {
            width: 46px;
            height: 46px;
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid rgba(31, 122, 224, 0.12);
        }

        .proof-cell {
            min-width: 132px;
        }

        .proof-thumb {
            width: 72px;
            height: 54px;
            border-radius: 12px;
            object-fit: cover;
            display: block;
            border: 1px solid rgba(137, 160, 188, 0.18);
            box-shadow: 0 8px 18px rgba(15, 32, 56, 0.12);
            margin-bottom: 8px;
        }

        .proof-link {
            color: var(--primary);
            font-weight: 700;
            text-decoration: none;
            font-size: 0.82rem;
        }

        .proof-missing {
            color: var(--muted);
            font-size: 0.82rem;
        }

        .btn-del,
        .btn-clear {
            border: none;
            padding: 11px 16px;
            border-radius: 12px;
            cursor: pointer;
            font-weight: 700;
            transition: 0.25s ease;
        }

        .btn-del {
            color: var(--danger);
            background: rgba(223, 77, 106, 0.08);
        }

        .btn-del:hover {
            background: rgba(223, 77, 106, 0.16);
        }

        .btn-clear {
            background: linear-gradient(135deg, var(--primary), #0f5cbc);
            color: white;
        }

        .btn-clear:hover {
            transform: translateY(-1px);
            box-shadow: 0 10px 22px rgba(31, 122, 224, 0.24);
        }

        .danger-btn {
            background: linear-gradient(135deg, var(--danger), #bf3050);
        }

        .search-row {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: center;
        }

        .stack {
            display: grid;
            gap: 16px;
        }

        .live-grid,
        .form-grid {
            display: grid;
            gap: 16px;
        }

        .live-grid {
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        }

        .form-grid {
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        }

        select,
        textarea {
            width: 100%;
            padding: 12px 14px;
            border-radius: 14px;
            border: 1px solid rgba(137, 160, 188, 0.34);
            background: rgba(255, 255, 255, 0.95);
            font: inherit;
            color: var(--text);
        }

        textarea {
            min-height: 110px;
            resize: vertical;
        }

        .live-card {
            padding: 18px;
            border-radius: 20px;
            border: 1px solid rgba(137, 160, 188, 0.18);
            background: rgba(255, 255, 255, 0.9);
            transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
        }

        .live-card.pulse {
            border-color: rgba(223, 77, 106, 0.35);
            box-shadow: 0 0 0 0 rgba(223, 77, 106, 0.24);
            animation: pulseRing 1.2s ease;
        }

        .thumb {
            width: 100%;
            max-height: 180px;
            object-fit: cover;
            border-radius: 14px;
            margin-top: 12px;
            border: 1px solid rgba(137, 160, 188, 0.18);
        }

        input {
            flex: 1 1 280px;
            min-width: 220px;
            padding: 12px 14px;
            border-radius: 14px;
            border: 1px solid rgba(137, 160, 188, 0.34);
            background: rgba(255, 255, 255, 0.95);
            font: inherit;
            color: var(--text);
        }

        .row-highlight {
            background: rgba(244, 169, 0, 0.12);
        }

        .muted-copy {
            color: var(--muted);
            line-height: 1.7;
        }

        .timeline-grid,
        .announcement-grid {
            display: grid;
            gap: 16px;
        }

        .timeline-grid {
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        }

        .timeline-card,
        .announcement-card {
            border-radius: 20px;
            border: 1px solid rgba(137, 160, 188, 0.18);
            padding: 18px;
            background: rgba(255, 255, 255, 0.88);
        }

        .timeline-card img {
            width: 100%;
            height: 160px;
            object-fit: cover;
            border-radius: 14px;
            margin-top: 12px;
            border: 1px solid rgba(137, 160, 188, 0.18);
        }

        .timeline-meta {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            align-items: center;
            margin-top: 10px;
            color: var(--muted);
            font-size: 0.84rem;
        }

        .stat-card.reveal,
        .panel.reveal {
            animation: riseIn 0.5s ease both;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(6px);
            }

            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        @keyframes riseIn {
            from {
                opacity: 0;
                transform: translateY(14px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        @keyframes pulseRing {
            0% { box-shadow: 0 0 0 0 rgba(223, 77, 106, 0.24); }
            100% { box-shadow: 0 0 0 18px rgba(223, 77, 106, 0); }
        }

        @media (max-width: 980px) {
            body {
                flex-direction: column;
                overflow: auto;
            }

            #side-nav {
                position: static;
                width: 100%;
                min-width: 100%;
                height: auto;
                box-shadow: none;
                top: auto;
                left: auto;
                bottom: auto;
                overflow: visible;
            }

            #content {
                margin-left: 0;
                width: 100%;
                max-width: 100%;
                height: auto;
                padding: 24px;
                overflow: visible;
            }

            .logout-link {
                margin-top: 10px;
            }
        }

        @media (max-width: 640px) {
            #side-nav {
                padding: 18px 14px;
            }

            .nav-copy {
                display: none;
            }

            .nav-link {
                margin-bottom: 4px;
                padding: 12px 14px;
            }

            #content {
                padding: 18px;
            }

            .panel,
            .stat-card {
                padding: 20px;
            }

            th,
            td {
                padding: 12px 8px;
            }

            .chart-shell {
                height: 260px;
            }

            /* Preserve every data column without allowing the page itself to overflow. */
            .panel:has(table) {
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
            }

            .panel:has(table) table {
                min-width: 650px;
            }

            .search-row > *,
            .form-grid .btn-clear,
            .form-grid a.btn-clear {
                width: 100%;
                justify-content: center;
            }
        }
        body.page-ready { opacity: 1; transform: translateY(0); }
        body.page-exit { opacity: 0; transform: translateY(8px); }
        body { transition: opacity 0.28s ease, transform 0.28s ease; }
        @media (prefers-reduced-motion: reduce) {
            body, body.page-ready, body.page-exit { transition: none; transform: none; opacity: 1; }
        }
    </style>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body>
    <div id="side-nav">
        <div class="nav-brand">Overwatch Admin</div>
        <p class="nav-copy">Track marks, logins, and proctoring events from a single statistical dashboard.</p>
        <div class="nav-link active" data-section="dashboard" onclick="showSection('dashboard', this)">Dashboard</div>
        <div class="nav-link" data-section="proctoring" onclick="showSection('proctoring', this)">Live Proctoring</div>
        <div class="nav-link" data-section="profiles" onclick="showSection('profiles', this)">Student Profiles</div>
        <div class="nav-link" data-section="records" onclick="showSection('records', this)">Examination Records</div>
        <div class="nav-link" data-section="create-exam" onclick="showSection('create-exam', this)">Create Exam</div>
        <div class="nav-link" data-section="settings" onclick="showSection('settings', this)">System Settings</div>
        <a href="/logout" class="logout-link">Logout</a>
    </div>

    <div id="content">
        <div id="dashboard" class="section active">
            <p class="eyebrow">Admin Analytics</p>
            <h1 class="page-title">Statistical View</h1>
            <p class="page-subtitle">This view combines exam marks, student login activity, and score improvement trends so the admin can quickly spot participation and performance changes.</p>

            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-label">Exams Submitted</div>
                    <div class="stat-value count-up" data-count="{{ submissions }}">{{ submissions }}</div>
                    <div class="stat-meta">Total completed exam attempts recorded.</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Average Marks</div>
                    <div class="stat-value"><span class="count-up" data-count="{{ avg_score }}">{{ avg_score }}</span> / 50</div>
                    <div class="stat-meta">Overall average score across stored results.</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Student Logins</div>
                    <div class="stat-value count-up" data-count="{{ total_student_logins }}">{{ total_student_logins }}</div>
                    <div class="stat-meta">{{ active_login_students }} unique students have logged in.</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Improved Students</div>
                    <div class="stat-value count-up" data-count="{{ improved_students }}">{{ improved_students }}</div>
                    <div class="stat-meta">Students whose latest mark is higher than their first.</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Violations Detected</div>
                    <div class="stat-value count-up" data-count="{{ violation_count }}">{{ violation_count }}</div>
                    <div class="stat-meta">All recorded proctoring alerts in the system.</div>
                </div>
            </div>

            <div class="panel">
                <div class="panel-head">
                    <h3>Year-wise Submissions</h3>
                    <div class="panel-note">Quick participation split by academic year</div>
                </div>
                <div class="year-stats-grid">
                    {% for year, count in year_stats.items() %}
                    <div class="year-card">
                        <div class="year-label">Year {{ year }}</div>
                        <div class="year-value">{{ count }}</div>
                    </div>
                    {% endfor %}
                </div>
            </div>

            <div class="charts-grid">
                <div class="panel">
                    <div class="panel-head">
                        <h3>Average Marks by Semester</h3>
                        <div class="panel-note">Bar chart</div>
                    </div>
                    {% if has_exam_data and marks_chart_labels %}
                    <div class="chart-shell">
                        <canvas id="marksChart"></canvas>
                    </div>
                    {% else %}
                    <div class="empty-state">No exam results are available yet. Once students submit exams, the marks chart will appear here.</div>
                    {% endif %}
                </div>

                <div class="panel">
                    <div class="panel-head">
                        <h3>Marks Distribution</h3>
                        <div class="panel-note">Pie chart</div>
                    </div>
                    {% if has_exam_data %}
                    <div class="chart-shell">
                        <canvas id="distributionChart"></canvas>
                    </div>
                    {% else %}
                    <div class="empty-state">No marks distribution to show yet because there are no saved exam records.</div>
                    {% endif %}
                </div>
            </div>

            <div class="charts-grid">
                <div class="panel">
                    <div class="panel-head">
                        <h3>Student Logins in the Last 7 Days</h3>
                        <div class="panel-note">Daily trend</div>
                    </div>
                    {% if has_login_data %}
                    <div class="chart-shell">
                        <canvas id="loginTrendChart"></canvas>
                    </div>
                    {% else %}
                    <div class="empty-state">Login tracking starts from this update onward. New student logins will begin filling this chart.</div>
                    {% endif %}
                </div>

                <div class="panel">
                    <div class="panel-head">
                        <h3>Top Improvers</h3>
                        <div class="panel-note">First exam vs latest exam</div>
                    </div>
                    {% if top_improvers %}
                    <table>
                        <thead>
                            <tr>
                                <th>Roll Number</th>
                                <th>Name</th>
                                <th>First Score</th>
                                <th>Latest Score</th>
                                <th>Improvement</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for student in top_improvers %}
                            <tr>
                                <td><span class="badge badge-info">{{ student.student_id }}</span></td>
                                <td>{{ student.name }}</td>
                                <td>{{ student.first_score }} / 50</td>
                                <td>{{ student.latest_score }} / 50</td>
                                <td><span class="badge badge-success">+{{ student.change }}</span></td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                    {% else %}
                    <div class="empty-state">Improvement data needs at least two exam attempts for the same student. Once repeat attempts happen, the top improvers table will update automatically.</div>
                    {% endif %}
                </div>
            </div>

            <div class="panel">
                <div class="panel-head">
                    <h3>Recent Student Logins</h3>
                    <div class="panel-note">Latest successful student sign-ins</div>
                </div>
                {% if recent_logins %}
                <table>
                    <thead>
                        <tr>
                            <th>Roll Number</th>
                            <th>Name</th>
                            <th>Login Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for login in recent_logins %}
                        <tr>
                            <td><span class="badge badge-info">{{ login[0] }}</span></td>
                            <td>{{ login[1] }}</td>
                            <td>{{ login[2] }}</td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
                {% else %}
                    <div class="empty-state">There are no tracked student logins yet. Students will appear here after their next successful login.</div>
                {% endif %}
            </div>

            <div class="panel">
                <div class="panel-head">
                    <h3>Open Notifications</h3>
                    <div class="panel-note">Severe cheating alerts and repeated suspicious actions</div>
                </div>
                {% if notifications %}
                <table>
                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>Type</th>
                            <th>Severity</th>
                            <th>Time</th>
                        </tr>
                    </thead>
                    <tbody id="notification-table">
                        {% for item in notifications %}
                        <tr>
                            <td>{{ item[1] }}</td>
                            <td>{{ item[2] }}</td>
                            <td><span class="badge badge-danger">{{ item[3] }}</span></td>
                            <td>{{ item[5] }}</td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
                {% else %}
                <div class="empty-state">No severe notifications are open right now.</div>
                {% endif %}
            </div>
        </div>

        <div id="proctoring" class="section">
            <p class="eyebrow">Monitoring</p>
            <h1 class="page-title">Live Violation Data</h1>
            <p class="page-subtitle">Review the latest proctoring alerts captured during exams, plus live active exam telemetry.</p>
            <div class="panel">
                <div class="panel-head">
                    <h3>Live Active Exams</h3>
                    <div class="panel-note">Current writer, timer, webcam frame, mic status, and live violation count</div>
                </div>
                {% if live_exams %}
                <div class="live-grid" id="live-exam-grid">
                    {% for exam in live_exams %}
                    <div class="live-card">
                        <strong>{{ exam.student_name or exam.student_id }}</strong>
                        <div class="muted-copy" style="margin-top:8px;">{{ exam.student_id }} | Year {{ exam.year_group }} | {{ exam.remaining_seconds or 0 }} sec left</div>
                        <div class="muted-copy">Mic: {{ exam.mic_status or 'unknown' }} | Violations: {{ exam.violation_count or 0 }}</div>
                        <div class="muted-copy">Risk: {{ exam.risk_score or 0 }} ({{ exam.risk_level or 'Low' }}) | Face Verified: {{ 'Yes' if exam.face_verified else 'No' }}</div>
                        {% if exam.current_frame %}
                        <img class="thumb" src="{{ exam.current_frame if exam.current_frame.startswith('data:') else url_for('static', filename=exam.current_frame) }}" alt="Live frame">
                        {% endif %}
                    </div>
                    {% endfor %}
                </div>
                {% else %}
                <div class="empty-state" id="live-exam-grid">No students are actively writing right now.</div>
                {% endif %}
            </div>
            <div class="panel">
                <div class="panel-head">
                    <h3>Admin Announcement Panel</h3>
                    <div class="panel-note">Send a live warning to one student or broadcast to every active writer</div>
                </div>
                <div class="stack">
                    <div class="form-grid">
                        <input id="announcement-student-id" placeholder="Student ID (leave blank to broadcast)">
                        <input id="announcement-message" placeholder="Type a warning or exam notice">
                    </div>
                    <div class="actions" style="display:flex;gap:12px;flex-wrap:wrap;">
                        <button class="btn-clear proctorx-btn-loading" type="button" onclick="sendAnnouncement()">Send Announcement</button>
                        <div class="muted-copy" id="announcement-feedback">Announcements appear in the student exam view as live toasts.</div>
                    </div>
                </div>
                <div class="announcement-grid" style="margin-top:18px;" id="announcement-history">
                    {% if announcements %}
                    {% for item in announcements %}
                    <div class="announcement-card">
                        <strong>{{ item[2] == 'individual' and item[1] or 'Broadcast' }}</strong>
                        <div class="muted-copy" style="margin-top:8px;">{{ item[3] }}</div>
                        <div class="timeline-meta"><span>{{ item[4] }}</span><span>{{ item[5] }}</span></div>
                    </div>
                    {% endfor %}
                    {% else %}
                    <div class="empty-state">No admin announcements have been sent yet.</div>
                    {% endif %}
                </div>
            </div>
            <div class="panel">
                <div class="panel-head">
                    <h3>Violation Replay Timeline</h3>
                    <div class="panel-note">Recent alert thumbnails with timestamps for fast case review</div>
                </div>
                {% if logs %}
                <div class="timeline-grid" id="violation-timeline">
                    {% for log in logs[:8] %}
                    <div class="timeline-card">
                        <span class="badge badge-danger">{{ log[6] }}</span>
                        <h4 style="margin-top:10px;">{{ log[2] }} | {{ log[1] }}</h4>
                        <p class="muted-copy" style="margin-top:8px;">{{ log[3] }}</p>
                        <div class="timeline-meta"><span>{{ log[8] or log[4] }}</span><span>Score {{ log[7] or 0 }}</span></div>
                        {% if log[5] %}
                        <a href="{{ url_for('static', filename=log[5]) }}" target="_blank" rel="noopener">
                            <img src="{{ url_for('static', filename=log[5]) }}" alt="Violation proof">
                        </a>
                        {% endif %}
                    </div>
                    {% endfor %}
                </div>
                {% else %}
                <div class="empty-state">No recent violation replay cards are available yet.</div>
                {% endif %}
            </div>
            <div class="panel">
                <table>
                    <thead>
                        <tr>
                            <th>Severity</th>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Violation</th>
                            <th>Time</th>
                            <th>Proof</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for log in logs %}
                        <tr>
                            <td><span class="badge badge-danger">{{ log[6] }}</span></td>
                            <td>{{ log[1] }}</td>
                            <td>{{ log[2] }}</td>
                            <td><span class="badge badge-danger">{{ log[3] }}</span></td>
                            <td>{{ log[8] or log[4] }}</td>
                            <td class="proof-cell">
                                {% if log[5] %}
                                <a href="{{ url_for('static', filename=log[5]) }}" target="_blank" rel="noopener">
                                    <img src="{{ url_for('static', filename=log[5]) }}" alt="Violation proof" class="proof-thumb">
                                </a>
                                <a href="{{ url_for('static', filename=log[5]) }}" target="_blank" rel="noopener" class="proof-link">View Proof</a>
                                {% else %}
                                <span class="proof-missing">No proof</span>
                                {% endif %}
                            </td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>

        <div id="profiles" class="section">
            <p class="eyebrow">Directory</p>
            <h1 class="page-title">Registered Student Details</h1>
            <p class="page-subtitle">Manage student records and profile information from one place.</p>
            <div class="panel">
                <table>
                    <thead>
                        <tr>
                            <th>Photo</th>
                            <th>Roll Number</th>
                            <th>Name</th>
                            <th>Branch</th>
                            <th>Semester</th>
                            <th>Phone</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for s in all_students %}
                        <tr id="student-{{ s[0] }}">
                            <td><img src="{{ url_for('static', filename='profiles/' + s[5]) }}" class="student-pic" alt="{{ s[1] }}"></td>
                            <td><span class="badge badge-info">{{ s[0] }}</span></td>
                            <td><strong>{{ s[1] }}</strong></td>
                            <td>{{ s[2] }}</td>
                            <td>{{ s[3] }}</td>
                            <td>{{ s[4] }}</td>
                            <td><button class="btn-del" onclick="deleteStudent('{{ s[0] }}')">Delete Profile</button></td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>

        <div id="records" class="section">
            <p class="eyebrow">Exams</p>
            <h1 class="page-title">Examination Records</h1>
            <p class="page-subtitle">Review saved marks, cheating risk, final proctoring decisions, and export filtered data.</p>
            <div class="panel">
                <div class="panel-head">
                    <h3>Filters And Export</h3>
                    <div class="panel-note">Branch, semester, date, and year exam</div>
                </div>
                <form method="get" action="/admin/dashboard" class="form-grid">
                    <select name="branch">
                        <option value="">All Branches</option>
                        {% for branch in filter_options.branches %}
                        <option value="{{ branch }}" {% if filters.branch == branch %}selected{% endif %}>{{ branch }}</option>
                        {% endfor %}
                    </select>
                    <select name="semester">
                        <option value="">All Semesters</option>
                        {% for semester in filter_options.semesters %}
                        <option value="{{ semester }}" {% if filters.semester == semester %}selected{% endif %}>{{ semester }}</option>
                        {% endfor %}
                    </select>
                    <input type="date" name="date" value="{{ filters.date }}">
                    <select name="year_group">
                        <option value="">All Year Exams</option>
                        {% for year in range(1, 5) %}
                        <option value="{{ year }}" {% if filters.year_group == (year|string) %}selected{% endif %}>Year {{ year }}</option>
                        {% endfor %}
                    </select>
                    <button class="btn-clear proctorx-btn-loading" type="submit">Apply Filters</button>
                    <a class="btn-clear proctorx-btn-loading" href="{{ url_for('export_admin_data', export_format='csv', branch=filters.branch, semester=filters.semester, date=filters.date, year_group=filters.year_group) }}" style="text-decoration:none;display:inline-flex;justify-content:center;align-items:center;">Export CSV</a>
                    <a class="btn-clear proctorx-btn-loading" href="{{ url_for('export_admin_data', export_format='pdf', branch=filters.branch, semester=filters.semester, date=filters.date, year_group=filters.year_group) }}" style="text-decoration:none;display:inline-flex;justify-content:center;align-items:center;">Export PDF</a>
                </form>
            </div>
            <div class="panel">
                <table>
                    <thead>
                        <tr>
                            <th>Case</th>
                            <th>Roll Number</th>
                            <th>Name</th>
                            <th>Branch</th>
                            <th>Semester</th>
                            <th>Marks Got</th>
                            <th>Risk</th>
                            <th>Decision</th>
                            <th>Submission Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for r in records %}
                        <tr>
                            <td>#{{ r[0] }}</td>
                            <td>{{ r[1] }}</td>
                            <td>{{ r[2] }}</td>
                            <td>{{ r[3] }}</td>
                            <td>{{ r[4] }}</td>
                            <td><strong>{{ r[5] }} / {{ r[6] }}</strong></td>
                            <td><span class="badge badge-info">{{ r[10] }} ({{ r[9] }})</span></td>
                            <td>
                                <select onchange="updateDecision({{ r[0] }}, this.value)">
                                    <option value="pending" {% if r[11] == 'pending' %}selected{% endif %}>Pending</option>
                                    <option value="clean" {% if r[11] == 'clean' %}selected{% endif %}>Clean</option>
                                    <option value="warning" {% if r[11] == 'warning' %}selected{% endif %}>Warning</option>
                                    <option value="malpractice_confirmed" {% if r[11] == 'malpractice_confirmed' %}selected{% endif %}>Malpractice Confirmed</option>
                                </select>
                            </td>
                            <td>{{ r[7] }}</td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>

        <div id="create-exam" class="section">
            <p class="eyebrow">Exam Builder</p>
            <h1 class="page-title">Create Exam</h1>
            <p class="page-subtitle">Manage the question bank and configure attempt rules, retake access, cooldown, duration, and face verification threshold from one dedicated section.</p>

            <div class="panel" id="question-bank">
                <div class="panel-head">
                    <h3>Question Bank Management</h3>
                    <div class="panel-note">Add, review, and delete questions by year, section, topic, and difficulty</div>
                </div>
                <form method="post" action="/admin/question_bank" class="stack">
                    <div class="form-grid">
                        <select name="year_group">
                            {% for year in range(1, 5) %}
                            <option value="{{ year }}">Year {{ year }}</option>
                            {% endfor %}
                        </select>
                        <select name="section_key">
                            <option value="section_a">Section A</option>
                            <option value="section_b">Section B</option>
                            <option value="section_c">Section C</option>
                        </select>
                        <input name="topic" placeholder="Topic">
                        <select name="difficulty">
                            <option value="easy">Easy</option>
                            <option value="medium">Medium</option>
                            <option value="hard">Hard</option>
                        </select>
                    </div>
                    <textarea name="question_text" placeholder="Question text"></textarea>
                    <input name="options" placeholder="Options separated by | for MCQ/True-False">
                    <input name="answer_text" placeholder="Correct answer">
                    <textarea name="explanation" placeholder="Explanation or revision note"></textarea>
                    <div><button type="submit" class="btn-clear proctorx-btn-loading">Add Question</button></div>
                </form>
                <br>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Year</th>
                            <th>Section</th>
                            <th>Topic</th>
                            <th>Difficulty</th>
                            <th>Question</th>
                            <th>Answer</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for q in question_bank_rows %}
                        <tr id="question-{{ q[0] }}">
                            <td>{{ q[0] }}</td>
                            <td>{{ q[1] }}</td>
                            <td>{{ q[2] }}</td>
                            <td>{{ q[3] }}</td>
                            <td>{{ q[4] }}</td>
                            <td>{{ q[5] }}</td>
                            <td>{{ q[6] }}</td>
                            <td><button class="btn-del" onclick="deleteQuestion({{ q[0] }})">Delete</button></td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>

            <div class="panel">
                <div class="panel-head">
                    <h3>Exam Attempt Control</h3>
                    <div class="panel-note">Configure attempts, retakes, cooldowns, duration, and face match threshold</div>
                </div>
                <form method="post" action="/admin/exam_settings" class="stack">
                    <div class="form-grid">
                        <label><input type="checkbox" name="one_attempt_only" {% if exam_settings.one_attempt_only %}checked{% endif %}> One attempt only</label>
                        <label><input type="checkbox" name="retake_allowed" {% if exam_settings.retake_allowed %}checked{% endif %}> Retake allowed</label>
                        <input type="number" min="1" name="max_attempts" value="{{ exam_settings.max_attempts }}" placeholder="Max attempts">
                        <input type="number" min="0" name="cooldown_minutes" value="{{ exam_settings.cooldown_minutes }}" placeholder="Cooldown minutes">
                        <input type="number" min="10" name="exam_duration_minutes" value="{{ exam_settings.exam_duration_minutes }}" placeholder="Duration minutes">
                        <input type="number" min="0.1" max="0.99" step="0.01" name="face_match_threshold" value="{{ exam_settings.face_match_threshold }}" placeholder="Face threshold">
                    </div>
                    <div><button class="btn-clear proctorx-btn-loading" type="submit">Save Exam Settings</button></div>
                </form>
            </div>
        </div>

        <div id="settings" class="section">
            <p class="eyebrow">Tools</p>
            <h1 class="page-title">System Settings</h1>
            <p class="page-subtitle">Search for a student quickly or manage stored proctoring logs.</p>

            <div class="panel">
                <div class="panel-head">
                    <h3>Search Student Info</h3>
                    <div class="panel-note">Jump directly to a profile by roll number</div>
                </div>
                <div class="search-row">
                    <input type="text" id="searchRoll" placeholder="Enter Roll Number">
                    <button class="btn-clear proctorx-btn-loading" onclick="searchStudent()">Search Student</button>
                </div>
            </div>

            <div class="panel">
                <div class="panel-head">
                    <h3>Data Management</h3>
                    <div class="panel-note">Danger zone</div>
                </div>
                <p class="muted-copy">This action permanently deletes all stored violation logs from the database. Analytics for student logins and marks will remain untouched.</p>
                <br>
                <button class="btn-clear danger-btn" onclick="clearLogs()">Clear All Violation Logs</button>
            </div>

        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <script>
        const adminSocket = window.io ? io() : {
            emit() {},
            on() {},
            disconnect() {}
        };
        let lastAlertStudentId = '';

        function showSection(id, btn) {
            document.querySelectorAll('.section').forEach(section => section.classList.remove('active'));
            document.querySelectorAll('.nav-link').forEach(link => link.classList.remove('active'));
            document.getElementById(id).classList.add('active');

            const activeButton = btn || document.querySelector(`.nav-link[data-section="${id}"]`);
            if (activeButton) {
                activeButton.classList.add('active');
            }
        }

        async function deleteStudent(sid) {
            if (await proctorxConfirm('This permanently deletes the student profile, exam records, login history, and violation evidence.', { type: 'danger', title: 'Delete student profile', confirmText: 'Delete permanently' })) {
                const res = await fetch(`/admin/delete_student/${sid}`, { method: 'POST' });
                const data = await res.json();
                if (data.status === 'success') {
                    const row = document.getElementById(`student-${sid}`);
                    if (row) {
                        row.remove();
                    }
                    await proctorxAlert('The student profile and linked records were removed.', { type: 'success', title: 'Profile deleted' });
                } else {
                    await proctorxAlert('The profile could not be deleted. Please try again.', { type: 'danger', title: 'Delete failed' });
                }
            }
        }

        async function sendAnnouncement() {
            const studentId = document.getElementById('announcement-student-id').value.trim().toUpperCase();
            const message = document.getElementById('announcement-message').value.trim();
            const feedback = document.getElementById('announcement-feedback');
            if (!message) {
                feedback.textContent = 'Type a message before sending the announcement.';
                return;
            }
            try {
                const res = await fetch('/admin/announce', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ student_id: studentId, message })
                });
                const data = await res.json();
                if (!res.ok || data.status !== 'success') {
                    feedback.textContent = data.message || 'Could not send the announcement.';
                    return;
                }
                feedback.textContent = `Announcement sent at ${data.created_at}. Delivered to ${data.delivered} active session(s).`;
                document.getElementById('announcement-message').value = '';
                prependAnnouncementHistory({
                    student_id: studentId,
                    audience: studentId ? 'individual' : 'broadcast',
                    message,
                    created_at: data.created_at,
                    created_by: 'ADMIN'
                });
            } catch (error) {
                feedback.textContent = 'Network error while sending the announcement.';
            }
        }

        function prependAnnouncementHistory(payload) {
            const container = document.getElementById('announcement-history');
            if (!container) return;
            const empty = container.querySelector('.empty-state');
            if (empty) empty.remove();
            const card = document.createElement('div');
            card.className = 'announcement-card';
            card.innerHTML = `
                <strong>${payload.audience === 'individual' ? payload.student_id : 'Broadcast'}</strong>
                <div class="muted-copy" style="margin-top:8px;">${payload.message}</div>
                <div class="timeline-meta"><span>${payload.created_at}</span><span>${payload.created_by || 'ADMIN'}</span></div>
            `;
            container.prepend(card);
        }

        async function deleteQuestion(id) {
            if (!await proctorxConfirm('This question will be removed from the managed question bank.', { type: 'danger', title: 'Delete question', confirmText: 'Delete question' })) return;
            const res = await fetch(`/admin/question_bank/${id}/delete`, { method: 'POST' });
            const data = await res.json();
            if (data.status === 'success') {
                document.getElementById(`question-${id}`)?.remove();
            }
        }

        async function updateDecision(resultId, decision) {
            const res = await fetch(`/admin/result/${resultId}/decision`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ decision })
            });
            const data = await res.json();
            if (data.status !== 'success') {
                await proctorxAlert(data.message || 'Could not update the review decision.', { type: 'danger', title: 'Decision update failed' });
            }
        }

        async function clearLogs() {
            if (await proctorxConfirm('This permanently removes all saved violation logs and their evidence images.', { type: 'danger', title: 'Clear violation logs', confirmText: 'Clear logs' })) {
                fetch('/admin/clear_logs', { method: 'POST' })
                    .then(() => location.reload());
            }
        }

        async function searchStudent() {
            const rollInput = document.getElementById('searchRoll');
            const roll = rollInput.value.trim().toUpperCase();

            document.querySelectorAll('#profiles tbody tr').forEach(row => row.classList.remove('row-highlight'));

            if (!roll) {
                await proctorxAlert('Enter a roll number to search the registered student directory.', { type: 'warning', title: 'Roll number required' });
                return;
            }

            const row = document.getElementById(`student-${roll}`);
            showSection('profiles');

            if (row) {
                row.classList.add('row-highlight');
                row.scrollIntoView({ behavior: 'smooth', block: 'center' });
            } else {
                await proctorxAlert('No registered student matches that roll number.', { type: 'info', title: 'Student not found' });
            }
        }

        const marksChartLabels = {{ marks_chart_labels | tojson }};
        const marksChartValues = {{ marks_chart_values | tojson }};
        const distributionLabels = {{ marks_distribution_labels | tojson }};
        const distributionValues = {{ marks_distribution_values | tojson }};
        const loginTrendLabels = {{ login_trend_labels | tojson }};
        const loginTrendValues = {{ login_trend_values | tojson }};
        const hasExamData = {{ has_exam_data | tojson }};
        const hasLoginData = {{ has_login_data | tojson }};

        function renderLiveExamCards(exams) {
            const container = document.getElementById('live-exam-grid');
            if (!container) return;
            if (!exams.length) {
                container.innerHTML = '<div class="empty-state">No students are actively writing right now.</div>';
                return;
            }
            container.innerHTML = exams.map(exam => `
                <div class="live-card ${lastAlertStudentId && lastAlertStudentId === exam.student_id ? 'pulse' : ''}" id="live-${exam.student_id}">
                    <strong>${exam.student_name || exam.student_id}</strong>
                    <div class="muted-copy" style="margin-top:8px;">${exam.student_id} | Year ${exam.year_group || '-'} | ${exam.remaining_seconds || 0} sec left</div>
                    <div class="muted-copy">Mic: ${exam.mic_status || 'unknown'} | Violations: ${exam.violation_count || 0}</div>
                    <div class="muted-copy">Risk: ${exam.risk_score || 0} (${exam.risk_level || 'Low'}) | Face Verified: ${exam.face_verified ? 'Yes' : 'No'}</div>
                    <div class="actions" style="display:flex;gap:10px;flex-wrap:wrap;margin-top:12px;">
                        <button class="btn-clear proctorx-btn-loading" type="button" onclick="quickWarn('${exam.student_id}')">Send Warning</button>
                    </div>
                    ${exam.current_frame ? `<img class="thumb" src="${exam.current_frame.startsWith('data:') ? exam.current_frame : `/static/${exam.current_frame}`}" alt="Live frame">` : ''}
                </div>
            `).join('');
            setTimeout(() => { lastAlertStudentId = ''; }, 1200);
        }

        function quickWarn(studentId) {
            document.getElementById('announcement-student-id').value = studentId;
            document.getElementById('announcement-message').value = 'Please stay in frame, remain in fullscreen, and avoid suspicious movement.';
            sendAnnouncement();
        }

        async function refreshLiveExams() {
            try {
                const res = await fetch('/admin/live_exams');
                const data = await res.json();
                if (data.status === 'success') {
                    renderLiveExamCards(data.live_exams || []);
                }
            } catch (error) {
                console.error(error);
            }
        }

        adminSocket.on('admin_notification', payload => {
            const table = document.getElementById('notification-table');
            if (!table) return;
            const row = document.createElement('tr');
            row.innerHTML = `<td>${payload.student_id}</td><td>${payload.type}</td><td><span class="badge badge-danger">${payload.severity}</span></td><td>${payload.created_at}</td>`;
            table.prepend(row);
            lastAlertStudentId = payload.student_id || '';
            const liveCard = document.getElementById(`live-${payload.student_id}`);
            if (liveCard) {
                liveCard.classList.remove('pulse');
                setTimeout(() => liveCard.classList.add('pulse'), 0);
            }
        });

        setInterval(refreshLiveExams, 5000);
        refreshLiveExams();

        document.querySelectorAll('.stat-card, .panel').forEach((node, index) => {
            node.classList.add('reveal');
            node.style.animationDelay = `${index * 35}ms`;
        });
        document.querySelectorAll('.count-up').forEach((node, index) => {
            const target = Number(node.dataset.count || 0);
            if (Number.isNaN(target)) return;
            const decimals = String(node.dataset.count || '').includes('.') ? 1 : 0;
            const duration = 950 + (index * 70);
            const start = performance.now();
            const tick = (now) => {
                const progress = Math.min(1, (now - start) / duration);
                const eased = 1 - Math.pow(1 - progress, 3);
                node.textContent = (target * eased).toFixed(decimals).replace(/\.0$/, '');
                if (progress < 1) requestAnimationFrame(tick);
                else node.textContent = String(target).replace(/\.0$/, '');
            };
            requestAnimationFrame(tick);
        });

        if (window.Chart) {
            Chart.defaults.color = '#66768d';
            Chart.defaults.font.family = "'Plus Jakarta Sans', sans-serif";

            if (hasExamData && marksChartLabels.length) {
                new Chart(document.getElementById('marksChart'), {
                    type: 'bar',
                    data: {
                        labels: marksChartLabels,
                        datasets: [{
                            label: 'Average Marks',
                            data: marksChartValues,
                            borderRadius: 12,
                            backgroundColor: ['#1f7ae0', '#2793d6', '#1aa7a1', '#f4a900', '#df4d6a', '#7b61ff'],
                            borderWidth: 0
                        }]
                    },
                    options: {
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { display: false }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                suggestedMax: 50,
                                ticks: { stepSize: 10 },
                                grid: { color: 'rgba(102, 118, 141, 0.12)' }
                            },
                            x: {
                                grid: { display: false }
                            }
                        }
                    }
                });
            }

            if (hasExamData && distributionValues.some(value => value > 0)) {
                new Chart(document.getElementById('distributionChart'), {
                    type: 'pie',
                    data: {
                        labels: distributionLabels,
                        datasets: [{
                            data: distributionValues,
                            backgroundColor: ['#df4d6a', '#f4a900', '#1aa7a1', '#1f7ae0'],
                            borderColor: '#f3f7fb',
                            borderWidth: 4
                        }]
                    },
                    options: {
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom'
                            }
                        }
                    }
                });
            }

            if (hasLoginData) {
                new Chart(document.getElementById('loginTrendChart'), {
                    type: 'line',
                    data: {
                        labels: loginTrendLabels,
                        datasets: [{
                            label: 'Student Logins',
                            data: loginTrendValues,
                            borderColor: '#1f7ae0',
                            backgroundColor: 'rgba(31, 122, 224, 0.14)',
                            fill: true,
                            tension: 0.35,
                            pointRadius: 4,
                            pointBackgroundColor: '#1f7ae0'
                        }]
                    },
                    options: {
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { display: false }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                ticks: { precision: 0 },
                                grid: { color: 'rgba(102, 118, 141, 0.12)' }
                            },
                            x: {
                                grid: { display: false }
                            }
                        }
                    }
                });
            }
        }
    </script>
    <script>
        (function () {
            const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            const enterPage = () => {
                document.body.classList.add('page-ready');
                document.body.classList.remove('page-exit');
            };
            window.transitionTo = function (url) {
                if (!url) return;
                if (reduceMotion) { window.location.href = url; return; }
                document.body.classList.remove('page-ready');
                document.body.classList.add('page-exit');
                setTimeout(() => { window.location.href = url; }, 220);
            };
            document.addEventListener('click', (event) => {
                const link = event.target.closest('a[href]');
                if (!link) return;
                const href = link.getAttribute('href') || '';
                if (!href || href.startsWith('#') || link.target === '_blank' || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
                const absoluteUrl = new URL(link.href, window.location.href);
                if (absoluteUrl.origin !== window.location.origin) return;
                event.preventDefault();
                transitionTo(absoluteUrl.href);
            });
            window.addEventListener('pageshow', enterPage);
            if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', enterPage);
            else enterPage();
        })();
    </script>

<button class="proctorx-fab" type="button" aria-label="Help" onclick="alert('Support center coming soon!')">
    <svg viewBox="0 0 24 24" aria-hidden="true" fill="currentColor">
        <path d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z"/>
    </svg>
</button>

</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Secure Assessment</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='tilt-effects.css') }}">
    <script src="{{ url_for('static', filename='tilt-effects.js') }}" defer></script>
    <style>
        :root {
            --primary: #23a6d5;
            --secondary: #23d5ab;
            --accent: #f1c40f;
            --danger: #e73c7e;
            --bg: #f8faff;
            --sidebar: #1a1a2e;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; scroll-behavior: smooth; }
        body { background-color: var(--bg); display: flex; height: 100vh; overflow: hidden; }

        /* --- Sidebar & UI --- */
        #sidebar { width: 350px; background: var(--sidebar); color: white; display: flex; flex-direction: column; padding: 30px 20px; box-shadow: 10px 0 30px rgba(0,0,0,0.1); z-index: 10; }
        #webcam-container { width: 100%; border-radius: 15px; overflow: hidden; border: 2px solid rgba(255,255,255,0.1); position: relative; background: #000; }
        video { width: 100%; transform: scaleX(-1); display: block; }
        .meter-container { background: rgba(255,255,255,0.1); height: 8px; border-radius: 4px; overflow: hidden; margin-top: 5px; }
        #audio-level { height: 100%; width: 0%; background: linear-gradient(to right, var(--secondary), var(--primary)); transition: width 0.05s; }
        #status-log { margin-top: 30px; flex-grow: 1; overflow-y: auto; }
        .alert-item { background: rgba(231, 60, 126, 0.1); border-left: 4px solid var(--danger); padding: 12px; border-radius: 8px; margin-bottom: 12px; font-size: 0.8rem; }

        /* --- Main Content --- */
        #main-wrapper { flex: 1; display: none; flex-direction: column; overflow: hidden; }
        #top-nav { padding: 20px 40px; background: white; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 2px 15px rgba(0,0,0,0.03); }
        #timer { font-size: 1.4rem; font-weight: 600; background: var(--accent); padding: 5px 20px; border-radius: 10px; }
        #exam-paper { padding: 40px; overflow-y: auto; flex-grow: 1; width: 100%; max-width: 900px; margin: 0 auto; }
        .section-header { background: var(--sidebar); color: white; padding: 12px 25px; border-radius: 12px; margin: 40px 0 20px 0; font-weight: 600; }
        .question-card { background: white; padding: 30px; border-radius: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.02); margin-bottom: 30px; border: 1px solid #edf2f7; }
        .mcq-option { display: block; margin: 12px 0; cursor: pointer; padding: 12px; border: 1px solid #eee; border-radius: 12px; transition: 0.2s; }
        .mcq-option:hover { background: #f9f9f9; border-color: var(--primary); }
        .ans-key { display: none; margin-top: 15px; padding: 10px; background: #e0ffe0; color: #23d5ab; border-radius: 8px; font-weight: 600; font-size: 0.85rem; }

        /* --- Result Analysis --- */
        #result-screen { display: none; position: fixed; inset: 0; background: var(--bg); z-index: 3000; overflow-y: auto; padding: 50px; flex-direction: column; align-items: center; }
        .score-circle { width: 200px; height: 200px; border-radius: 50%; border: 10px solid var(--secondary); display: flex; flex-direction: column; justify-content: center; align-items: center; margin-bottom: 30px; background: white; }
        .analysis-card { background: white; padding: 30px; border-radius: 20px; width: 100%; max-width: 800px; box-shadow: 0 10px 30px rgba(0,0,0,0.05); color: var(--sidebar); text-align: left; }
        .summary-item { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }

        /* --- SECURITY ALERT CSS --- */
        .full-overlay { display: none; position: fixed; inset: 0; background: rgba(26, 26, 46, 0.98); backdrop-filter: blur(15px); z-index: 2000; flex-direction: column; justify-content: center; align-items: center; color: white; text-align: center; padding: 40px; }
        .modal-card { background: white; color: var(--sidebar); padding: 40px; border-radius: 25px; width: 100%; max-width: 500px; }
        .btn-confirm { background: var(--secondary); color: white; padding: 12px 30px; border: none; border-radius: 10px; cursor: pointer; margin: 10px; font-weight: 600; }
        .btn-cancel { background: #dfe6e9; color: #636e72; padding: 12px 30px; border: none; border-radius: 10px; cursor: pointer; margin: 10px; }
        
        .device-alert { position: fixed; inset: 0; background: rgba(231, 60, 126, 0.95); z-index: 9999; display: flex; flex-direction: column; justify-content: center; align-items: center; color: white; text-align: center; animation: pulse 0.4s infinite; }
        @keyframes pulse { 0% { opacity: 0.9; } 50% { opacity: 1; } 100% { opacity: 0.9; } }
    </style>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body onclick="startAudio()">

    <div id="permission-shield" style="position:fixed; inset:0; background:var(--sidebar); z-index:9999; display:flex; flex-direction:column; justify-content:center; align-items:center; color:white;">
        <h1>🛡️ Hardware Security Check</h1>
        <p style="margin: 20px 0; color: #aaa;">Enable Camera & Mic to start your Group {{ year_group }} Assessment.</p>
        <button onclick="initMedia()" class="btn-confirm" style="background:var(--primary); padding:20px 50px;">Start Session</button>
    </div>

    <div id="sidebar" style="visibility: hidden;">
        <div class="proctor-header" style="font-weight: 600; font-size: 0.9rem; margin-bottom: 10px;"><span style="color: red;">●</span> Live AI Monitoring</div>
        <div id="webcam-container"><video id="webcam" autoplay playsinline muted></video></div>
        <div class="meter-box" style="margin-top: 20px;">
            <span class="meter-label" style="font-size: 0.7rem; color: #aaa; display: block;">ENVIRONMENTAL AUDIO</span>
            <div class="meter-container"><div id="audio-level"></div></div>
        </div>
        <div id="status-log"></div>
    </div>

    <div id="main-wrapper">
        <nav id="top-nav">
            <div class="student-pill"><strong>Student:</strong> {{ student_name }} | <strong>ID:</strong> {{ student_id }}</div>
            <div id="timer">60:00</div>
        </nav>
        <div id="exam-paper">
            <div id="questions-container"></div>
            <button class="btn-confirm" style="width: 100%; padding: 20px; margin-top: 20px;" onclick="confirmSubmit()">FINISH ASSESSMENT</button>
        </div>
    </div>

    <div id="submit-modal" class="full-overlay">
        <div class="modal-card">
            <h2>Confirm Submission</h2>
            <p style="margin: 20px 0; color: #666;">Are you sure? Your answers will be graded immediately.</p>
            <button class="btn-confirm" onclick="finalProcess()">Yes, Submit</button>
            <button class="btn-cancel" onclick="closeModal()">Cancel</button>
        </div>
    </div>

    <div id="result-screen">
        <h1 style="margin-bottom: 10px; color: var(--sidebar);">Exam Completed!</h1>
        <div class="score-circle">
            <h1 id="final-score" style="font-size: 3rem; color: var(--secondary);">0</h1>
            <span style="font-weight: 600; color: var(--sidebar);">/ 50</span>
        </div>
        
        <div class="analysis-card">
            <h3 style="margin-bottom: 20px;">Section-wise Performance Analysis</h3>
            <div class="summary-item"><span>Section A (Fundamentals)</span><strong id="sec1-res">0 / 10</strong></div>
            <div class="summary-item"><span>Section B (Analytical)</span><strong id="sec2-res">0 / 20</strong></div>
            <div class="summary-item" style="border: none;"><span>Section C (Professional)</span><strong id="sec3-res">0 / 20</strong></div>
            
            <button class="btn-confirm" style="margin-top: 30px; width: 100%;" onclick="viewAnalysis()">View Analysis (Check Answers)</button>
            <button class="btn-confirm" style="margin-top: 10px; width: 100%; background: #636e72;" onclick="window.location.href='/logout'">Exit Portal</button>
        </div>
    </div>

    <script>
        const socket = window.io ? io() : {
            emit() {},
            on() {},
            disconnect() {}
        };
        const studentInfo = "{{ student_id }} - {{ student_name }}";
        const video = document.getElementById('webcam');
        const log = document.getElementById('status-log');
        const audioBar = document.getElementById('audio-level');
        const timerDisplay = document.getElementById('timer');
        let audioCtx, timeLeft = 60 * 60, timerStarted = false;
        let correctAnswers = [];

        // --- 1. ENHANCED RESTRICTED KEY/ACTION DETECTION ---
        ['copy', 'paste', 'contextmenu'].forEach(evt => {
            document.addEventListener(evt, (e) => {
                e.preventDefault();
                const reason = evt === 'contextmenu' ? "Right Click" : evt.charAt(0).toUpperCase() + evt.slice(1);
                triggerVisualAlert(`🚫 Restricted Action Used (${reason})`);
                socket.emit('tab_switch', { student_info: studentInfo, msg: `🚫 Restricted Action: ${reason}` });
            });
        });

        document.onkeydown = (e) => {
            if (e.ctrlKey && [67, 86, 85, 73, 83].includes(e.keyCode)) {
                triggerVisualAlert("🚫 Restricted Key Used");
                socket.emit('tab_switch', { student_info: studentInfo, msg: "🚫 Restricted Keys" });
                return false;
            }
        };

        function triggerVisualAlert(msg) {
            addLog(msg);
            const overlay = document.createElement('div');
            overlay.className = "device-alert";
            overlay.innerHTML = `<h1>🚨 SECURITY ALERT 🚨</h1><p>${msg}</p>`;
            document.body.appendChild(overlay);
            setTimeout(() => overlay.remove(), 1500);
        }

        // --- 2. EXAM GENERATION (50 MCQs: 10 + 20 + 20) ---
        function generateExam() {
            const container = document.getElementById('questions-container');
            let html = ""; correctAnswers = [];
            const sections = [
                { title: "Section A: Fundamentals (10 Marks)", count: 10 },
                { title: "Section B: Analytical (20 Marks)", count: 20 },
                { title: "Section C: Professional (20 Marks)", count: 20 }
            ];

            sections.forEach((sec, sIdx) => {
                html += `<div class="section-header">${sec.title}</div>`;
                for(let i = 0; i < sec.count; i++) {
                    let qIdx = correctAnswers.length;
                    let qData = { 
                        q: `Year {{ year_group }} - Sample MCQ Question ${qIdx+1}?`, 
                        o: ["Option A", "Option B", "Option C", "Option D"], 
                        a: "Option A" 
                    };
                    correctAnswers.push(qData.a);
                    html += `
                        <div class="question-card">
                            <p><strong>Q${qIdx+1}:</strong> ${qData.q}</p>
                            ${qData.o.map(opt => `<label class="mcq-option"><input type="radio" name="q${qIdx}" value="${opt}"> ${opt}</label>`).join('')}
                            <div class="ans-key" id="ans-${qIdx}">✅ Correct Answer: ${qData.a}</div>
                        </div>`;
                }
            });
            container.innerHTML = html;
        }

        function confirmSubmit() { document.getElementById('submit-modal').style.display = 'flex'; }
        function closeModal() { document.getElementById('submit-modal').style.display = 'none'; }

        // --- 3. FINAL GRADING & SECTION-WISE MARKS ---
        function finalProcess() {
            let secScores = [0, 0, 0];
            document.querySelectorAll('input[type="radio"]:checked').forEach(rb => {
                let idx = parseInt(rb.name.substring(1));
                if(rb.value === correctAnswers[idx]) {
                    if(idx < 10) secScores[0]++;
                    else if(idx < 30) secScores[1]++;
                    else secScores[2]++;
                }
            });

            const total = secScores.reduce((a,b) => a+b, 0);
            document.getElementById('submit-modal').style.display = 'none';
            document.getElementById('result-screen').style.display = 'flex';
            document.getElementById('final-score').innerText = total;
            document.getElementById('sec1-res').innerText = `${secScores[0]} / 10`;
            document.getElementById('sec2-res').innerText = `${secScores[1]} / 20`;
            document.getElementById('sec3-res').innerText = `${secScores[2]} / 20`;

            // Sync with backend
            fetch('/submit_exam', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ score: total, total: 50 })
            });
        }

        function viewAnalysis() {
            document.getElementById('result-screen').style.display = 'none';
            document.querySelectorAll('.ans-key').forEach(el => el.style.display = 'block');
            window.scrollTo(0,0);
        }

        // --- 4. CORE PROCTORING & HARDWARE ---
        function startAudio() { if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume(); }

        function initMedia() {
            navigator.mediaDevices.getUserMedia({ video: true, audio: true })
            .then(stream => {
                document.getElementById('permission-shield').style.display = 'none';
                document.getElementById('main-wrapper').style.display = 'flex';
                document.getElementById('sidebar').style.visibility = 'visible';
                video.srcObject = stream;
                setupAudio(stream);
                startAI();
                startTimer();
                generateExam();
            });
        }

        function setupAudio(stream) {
            audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            const source = audioCtx.createMediaStreamSource(stream);
            const analyser = audioCtx.createAnalyser();
            analyser.fftSize = 256; source.connect(analyser);
            const dataArray = new Uint8Array(analyser.frequencyBinCount);
            function renderFrame() {
                analyser.getByteFrequencyData(dataArray);
                let avg = dataArray.reduce((a,b) => a+b) / dataArray.length;
                audioBar.style.width = Math.min(100, avg * 3.5) + "%";
                if (avg > 50) socket.emit('audio_violation', { student_info: studentInfo });
                requestAnimationFrame(renderFrame);
            }
            renderFrame();
        }

        function startAI() {
            setInterval(() => {
                if (!video.videoWidth) return;
                const canvas = document.createElement('canvas');
                canvas.width = 320; canvas.height = 240; 
                canvas.getContext('2d').drawImage(video, 0, 0, 320, 240);
                socket.emit('video_frame', { image: canvas.toDataURL('image/jpeg', 0.6), student_info: studentInfo });
            }, 500); 
        }

        function startTimer() {
            timerStarted = true;
            setInterval(() => {
                let m = Math.floor(timeLeft / 60), s = timeLeft % 60;
                timerDisplay.innerText = `${m}:${s < 10 ? '0' : ''}${s}`;
                if (timeLeft-- <= 0) finalProcess();
            }, 1000);
        }

        function addLog(msg) {
            const item = document.createElement('div');
            item.className = 'alert-item';
            item.innerText = `⚠️ ${new Date().toLocaleTimeString()}: ${msg}`;
            log.prepend(item);
        }

        window.onblur = () => { if (timerStarted) socket.emit('tab_switch', { student_info: studentInfo, msg: "Tab Switch / Window Minimized" }); };
        socket.on('cheat_alert', d => d.alerts.forEach(a => { addLog(a); if(a.includes("phone")) triggerVisualAlert(a); }));
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ exam_payload.paper_title }}</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
    <script>
        document.documentElement.dataset.theme = localStorage.getItem('portal-theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <link rel="stylesheet" href="{{ url_for('static', filename='tilt-effects.css') }}">
    <script src="{{ url_for('static', filename='tilt-effects.js') }}" defer></script>
    <style>
        :root{
            --bg:#f4f7f6;
            --bg-soft:#eef6ff;
            --panel:rgba(255,255,255,.92);
            --panel-strong:rgba(255,255,255,.98);
            --line:rgba(137,160,188,.18);
            --text:#1f2a36;
            --muted:#66768d;
            --primary:#23a6d5;
            --primary-strong:#1f7ae0;
            --teal:#18a07f;
            --gold:#c87d00;
            --danger:#cc4665;
            --danger-soft:rgba(231,60,126,.12);
            --ok-soft:rgba(24,160,127,.12);
            --shadow:0 20px 45px rgba(15,32,56,.12);
        }
        html[data-theme='dark']{
            --bg:#061426;--bg-soft:#0a1c36;--panel:rgba(7,20,39,.78);--panel-strong:rgba(7,20,39,.94);
            --line:rgba(180,214,255,.18);--text:#eaf3ff;--muted:#a7b6cb;--primary:#4ee6ff;--primary-strong:#8ca4ff;
            --teal:#72f4c8;--gold:#ffd36c;--danger:#ff839d;--danger-soft:rgba(255,131,157,.12);--ok-soft:rgba(114,244,200,.12);
            --shadow:0 24px 64px rgba(0,0,0,.3)
        }
        *{box-sizing:border-box;margin:0;padding:0}
        html,body{min-height:100%;height:100%}
        body{
            font-family:'Plus Jakarta Sans',sans-serif;
            color:var(--text);
            display:flex;
            background:
                radial-gradient(circle at top left, rgba(35,166,213,.12), transparent 22%),
                radial-gradient(circle at bottom right, rgba(24,160,127,.08), transparent 18%),
                linear-gradient(160deg, #f7fbff 0%, #f4f7f6 45%, #eef4fb 100%);
            height:100vh;
            overflow:visible;
            transition:opacity .28s ease, transform .28s ease;
        }
        html[data-theme='dark'] body{background:radial-gradient(circle at top left, rgba(61,168,255,.24), transparent 24%),radial-gradient(circle at bottom right, rgba(135,87,255,.18), transparent 22%),linear-gradient(130deg,#07192f 0%,#071126 45%,#100d2d 100%)}
        html[data-theme='dark'] #permission-shield{background:rgba(4,13,29,.96)}
        html[data-theme='dark'] .gateway-shell,html[data-theme='dark'] .gateway-side,html[data-theme='dark'] #sidebar,html[data-theme='dark'] #top-nav,html[data-theme='dark'] #progress-rail{background:rgba(7,20,39,.88);border-color:var(--line)}
        html[data-theme='dark'] .kpi-card,html[data-theme='dark'] .check-card,html[data-theme='dark'] .status-card,html[data-theme='dark'] .violation-score,html[data-theme='dark'] .top-bar-card,html[data-theme='dark'] .rail-card,html[data-theme='dark'] .chip,html[data-theme='dark'] .question-card,html[data-theme='dark'] .opt,html[data-theme='dark'] input[type=text]{background:rgba(255,255,255,.055);border-color:var(--line)}
        /* Large containers use explicit light backgrounds in the base exam CSS. Override them as a set. */
        html[data-theme='dark'] .panel,html[data-theme='dark'] .section-card,html[data-theme='dark'] .review,html[data-theme='dark'] .summary-chip,html[data-theme='dark'] .modal{background:rgba(7,20,39,.88)!important;border-color:var(--line)!important;box-shadow:var(--shadow)!important}
        html[data-theme='dark'] .question-card,html[data-theme='dark'] .review-item,html[data-theme='dark'] .opt{background:rgba(255,255,255,.045)!important;border-color:rgba(180,214,255,.14)!important}
        html[data-theme='dark'] #exam-paper{background:rgba(4,13,29,.28)}
        html[data-theme='dark'] .toast{background:rgba(7,20,39,.98);border-color:var(--line);color:var(--text)}
        html[data-theme='dark'] .secondary{color:#dff7ff;background:rgba(255,255,255,.07);border-color:var(--line)}
        html[data-theme='dark'] .scan-stage{background:rgba(255,255,255,.04);border-color:var(--line)}
        html[data-theme='dark'] .trust-badge::before{background:rgba(7,20,39,.95);border-color:var(--line)}
        body.page-ready{opacity:1;transform:translateY(0)}
        body.page-exit{opacity:0;transform:translateY(8px)}
        #submit-modal,#result-screen{position:fixed;inset:0;z-index:2000}
        #permission-shield{
            position:fixed;
            inset:0;
            display:flex;align-items:flex-start;justify-content:center;padding:28px;
            min-height:100vh;min-height:100dvh;
            background:rgba(244,247,246,.96);backdrop-filter:blur(10px);overflow:auto;
            z-index:9999
        }
        .gateway-shell{
            width:min(1080px,100%);
            background:linear-gradient(180deg, rgba(255,255,255,.98), rgba(248,251,255,.98));
            border:1px solid rgba(137,160,188,.18);
            border-radius:32px;
            box-shadow:var(--shadow);
            display:grid;
            grid-template-columns:minmax(0,1.15fr) minmax(320px,.85fr);
            overflow:hidden;
            margin:0 auto
        }
        .gateway-shell > *{min-height:0}
        .gateway-main,.gateway-side{padding:24px;min-height:0;overflow:visible}
        .gateway-main{
            background:
                linear-gradient(145deg, rgba(35,166,213,.08), transparent 45%),
                linear-gradient(0deg, rgba(255,255,255,.01), rgba(255,255,255,.01))
        }
        .gateway-side{border-left:1px solid rgba(137,160,188,.14);background:rgba(244,249,255,.86)}
        .eyebrow{display:inline-flex;align-items:center;gap:8px;font-size:.76rem;letter-spacing:.18em;text-transform:uppercase;color:var(--primary);font-weight:700;margin-bottom:14px}
        .gateway-main h1{font-family:'Space Grotesk',sans-serif;font-size:clamp(2rem,4vw,3.1rem);margin-bottom:14px}
        .lead{color:var(--muted);line-height:1.75;max-width:640px}
        .readiness-grid,.gateway-kpis,.status-ribbon,.summary-grid,.top-bar-grid,.trust-grid,.progress-grid{display:grid;gap:14px}
        .gateway-kpis{grid-template-columns:repeat(auto-fit,minmax(170px,1fr));margin-top:16px}
        .kpi-card,.check-card,.sidebar-card,.section-card,.question-card,.review,.summary-chip,.modal,.status-card{
            border:1px solid var(--line);
            background:var(--panel);
            border-radius:24px;
            box-shadow:var(--shadow)
        }
        .kpi-card{padding:16px}
        .kpi-label{font-size:.76rem;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:8px}
        .kpi-value{font-family:'Space Grotesk',sans-serif;font-size:1.5rem}
        .readiness-grid{margin-top:14px}
        .check-card{padding:18px;background:rgba(255,255,255,.88)}
        .check-row{display:flex;justify-content:space-between;align-items:center;gap:14px;padding:12px 0;border-bottom:1px solid rgba(137,160,188,.1)}
        .check-row:last-child{border-bottom:none;padding-bottom:0}
        .check-row:first-child{padding-top:0}
        .check-copy strong{display:block;margin-bottom:5px}
        .check-copy span{font-size:.86rem;color:var(--muted)}
        .check-status{min-width:108px;text-align:center;padding:9px 12px;border-radius:999px;font-size:.78rem;font-weight:700;letter-spacing:.06em;text-transform:uppercase}
        .check-status.pending{background:rgba(244,179,61,.14);color:var(--gold)}
        .check-status.ok{background:var(--ok-soft);color:var(--teal)}
        .check-status.error{background:var(--danger-soft);color:var(--danger)}
        .face-verify-shell{
            margin-top:16px;padding:16px;border-radius:24px;border:1px solid rgba(35,166,213,.18);
            background:linear-gradient(180deg, rgba(35,166,213,.08), rgba(35,166,213,.02))
        }
        .scan-stage{position:relative;height:124px;border-radius:20px;background:linear-gradient(180deg, #f5faff, #edf4fb);overflow:hidden;border:1px solid rgba(137,160,188,.14)}
        .scan-stage::before{
            content:"";position:absolute;inset:18px;border:1px solid rgba(35,166,213,.3);border-radius:18px
        }
        .scan-line{
            position:absolute;left:24px;right:24px;height:2px;top:24px;border-radius:999px;
            background:linear-gradient(90deg, transparent, rgba(35,166,213,.2), #23a6d5, rgba(35,166,213,.2), transparent);
            box-shadow:0 0 24px rgba(35,166,213,.35);
            opacity:0;
            transform:translateY(0)
        }
        .scan-stage.scanning .scan-line{opacity:1;animation:scanMove 1.5s linear infinite}
        .scan-stage.success{box-shadow:inset 0 0 0 1px rgba(24,160,127,.28), 0 0 28px rgba(24,160,127,.12)}
        .scan-stage.error{animation:shakeX .34s ease}
        .scan-face{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:3.1rem;color:rgba(31,42,54,.78)}
        .scan-caption{margin-top:10px;color:var(--muted);line-height:1.6}
        .actions{display:flex;gap:12px;flex-wrap:wrap}
        button{
            border:none;border-radius:16px;padding:13px 18px;font-weight:700;cursor:pointer;
            font:inherit;transition:transform .2s ease, box-shadow .2s ease, opacity .2s ease
        }
        a.primary,a.secondary{
            display:inline-flex;align-items:center;justify-content:center;text-decoration:none
        }
        button:hover{transform:translateY(-1px)}
        button:disabled{opacity:.65;cursor:not-allowed;transform:none}
        .primary{background:linear-gradient(135deg,var(--primary),var(--primary-strong));color:#04101b;box-shadow:0 14px 28px rgba(30,140,255,.26)}
        .secondary{background:rgba(137,160,188,.14);color:var(--text);border:1px solid rgba(137,160,188,.12)}
        .sidebar-card{padding:18px}
        .sidebar-title{font-size:.78rem;letter-spacing:.14em;text-transform:uppercase;color:var(--primary);margin-bottom:10px}
        #sidebar{width:380px;min-width:380px;background:rgba(255,255,255,.82);border-right:1px solid rgba(137,160,188,.12);padding:20px;display:none;flex-direction:column;gap:14px;overflow:auto}
        #webcam-shell{position:relative;border-radius:22px;overflow:hidden;background:#000}
        video{width:100%;display:block;transform:scaleX(-1)}
        .camera-overlay{
            position:absolute;inset:14px;border-radius:18px;border:1px solid rgba(35,166,213,.28);pointer-events:none;
            box-shadow:inset 0 0 0 1px rgba(255,255,255,.4)
        }
        .camera-overlay::before,.camera-overlay::after{
            content:"";position:absolute;width:28px;height:28px;border-color:#5bd2ff;border-style:solid
        }
        .camera-overlay::before{top:-1px;left:-1px;border-width:2px 0 0 2px;border-top-left-radius:16px}
        .camera-overlay::after{bottom:-1px;right:-1px;border-width:0 2px 2px 0;border-bottom-right-radius:16px}
        .status-ribbon{grid-template-columns:repeat(2,minmax(0,1fr))}
        .status-card{padding:16px;background:rgba(255,255,255,.65)}
        .status-card strong{display:block;margin-bottom:6px}
        .status-copy{font-size:.9rem;color:var(--muted);line-height:1.6}
        .meter{height:10px;border-radius:999px;background:rgba(137,160,188,.14);overflow:hidden}
        #audio-level{height:100%;width:0;background:linear-gradient(90deg,var(--teal),var(--primary),var(--gold))}
        .trust-grid{grid-template-columns:112px 1fr;align-items:center}
        .trust-badge{
            width:112px;height:112px;border-radius:50%;display:flex;align-items:center;justify-content:center;
            background:conic-gradient(var(--teal) 0turn, rgba(137,160,188,.14) 0turn);
            position:relative
        }
        .trust-badge::before{
            content:"";position:absolute;inset:10px;border-radius:50%;background:rgba(255,255,255,.96);border:1px solid rgba(137,160,188,.08)
        }
        .trust-badge span{position:relative;z-index:1;font-family:'Space Grotesk',sans-serif;font-size:1.9rem}
        .trust-copy strong{display:block;font-size:1.05rem;margin-bottom:6px}
        .trust-copy p{color:var(--muted);line-height:1.6;font-size:.92rem}
        .violation-score{padding:16px;border-radius:18px;background:rgba(255,255,255,.72);border:1px solid rgba(137,160,188,.12)}
        .violation-score strong{display:block;font-size:1.15rem;margin:6px 0 4px}
        #status-log{max-height:260px;overflow:auto;padding-right:4px}
        .alert-item{
            background:rgba(255,255,255,.04);border-left:3px solid var(--danger);padding:12px;border-radius:14px;
            margin-bottom:10px;font-size:.84rem;line-height:1.55;animation:slideUp .34s ease
        }
        #main-wrapper{
            display:none;
            min-width:0;
            flex:1;
            min-height:100vh;
            height:100vh;
            overflow:hidden;
            flex-direction:column
        }
        #top-nav{
            display:grid;grid-template-columns:minmax(0,1fr) auto auto;gap:16px;padding:18px 22px;
            border-bottom:1px solid rgba(137,160,188,.12);background:rgba(255,255,255,.84);backdrop-filter:blur(12px);
            position:sticky;top:0;z-index:80;flex:0 0 auto
        }
        .top-bar-grid{grid-template-columns:repeat(3,minmax(0,1fr))}
        .top-bar-card{
            padding:14px 16px;border-radius:18px;border:1px solid rgba(137,160,188,.12);background:rgba(255,255,255,.72)
        }
        .top-bar-card span{display:block;color:var(--muted);font-size:.78rem;margin-bottom:6px;text-transform:uppercase;letter-spacing:.08em}
        .top-bar-card strong{font-size:.96rem}
        .timer-wrap{
            display:flex;align-items:center;gap:14px;padding:12px 16px;border-radius:22px;
            border:1px solid rgba(200,125,0,.18);background:rgba(200,125,0,.08)
        }
        .timer-ring{width:64px;height:64px;position:relative}
        .timer-ring svg{transform:rotate(-90deg)}
        .timer-ring circle{fill:none;stroke-width:8}
        .timer-ring .bg{stroke:rgba(255,255,255,.08)}
        .timer-ring .progress{stroke:var(--gold);stroke-linecap:round;transition:stroke-dashoffset .5s ease, stroke .3s ease}
        .timer-meta strong{display:block;font-family:'Space Grotesk',sans-serif;font-size:1.4rem}
        .timer-meta span{display:block;font-size:.8rem;color:var(--muted);margin-top:3px}
        #exam-shell{
            display:grid;
            grid-template-columns:280px minmax(0,1fr);
            min-height:0;
            flex:1;
            overflow:hidden;
            align-items:start
        }
        #progress-rail{
            position:sticky;top:0;height:100%;min-height:0;overflow:auto;padding:18px;border-right:1px solid rgba(137,160,188,.1);
            background:rgba(248,251,255,.92)
        }
        .rail-card{padding:18px;border-radius:24px;border:1px solid rgba(137,160,188,.12);background:rgba(255,255,255,.72);margin-bottom:16px}
        .rail-title{font-size:.78rem;letter-spacing:.14em;text-transform:uppercase;color:var(--primary);margin-bottom:12px}
        .progress-grid{grid-template-columns:repeat(5,minmax(0,1fr))}
        .progress-pill{
            height:42px;border-radius:14px;border:1px solid rgba(137,160,188,.14);background:rgba(255,255,255,.72);
            color:var(--text);font-weight:700
        }
        .progress-pill.answered{background:rgba(43,214,176,.12);border-color:rgba(43,214,176,.22)}
        .progress-pill.flagged{background:rgba(244,179,61,.15);border-color:rgba(244,179,61,.28)}
        .progress-pill.active{box-shadow:0 0 0 2px rgba(69,194,255,.34) inset}
        .flag-summary{display:flex;justify-content:space-between;color:var(--muted);font-size:.9rem}
        .rail-section-link{
            width:100%;text-align:left;padding:12px 14px;border-radius:16px;background:rgba(255,255,255,.72);color:var(--text);
            border:1px solid rgba(137,160,188,.1);margin-bottom:10px
        }
        #exam-paper{
            height:100%;
            min-height:0;
            overflow:auto;
            padding:22px 24px 34px;
            scroll-behavior:smooth;
            scrollbar-gutter:stable
        }
        .shell{max-width:1040px;margin:0 auto}
        .panel{padding:24px;border-radius:28px;border:1px solid rgba(137,160,188,.14);background:rgba(255,255,255,.82);box-shadow:var(--shadow);margin-bottom:18px}
        .panel h1{font-family:'Space Grotesk',sans-serif;font-size:2rem;margin-bottom:10px}
        .muted{color:var(--muted);line-height:1.7}
        .pattern{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-top:18px}
        .chip,.summary-chip{padding:16px;border-radius:18px;background:rgba(255,255,255,.72);border:1px solid rgba(137,160,188,.12)}
        .section-card{padding:20px;margin-bottom:18px;position:relative;overflow:hidden;animation:cardReveal .5s ease both;background:rgba(255,255,255,.82)}
        .section-head{display:flex;justify-content:space-between;gap:16px;align-items:flex-start;margin-bottom:16px}
        .section-card h2{font-family:'Space Grotesk',sans-serif;margin-bottom:6px}
        .section-copy{color:var(--muted);line-height:1.6}
        .section-actions{display:flex;gap:10px;flex-wrap:wrap}
        .nav-mini{padding:10px 14px;border-radius:14px;font-size:.9rem}
        .question-stack{display:grid;gap:14px}
        .question-card{padding:18px;border-radius:20px;background:rgba(255,255,255,.72);transition:transform .22s ease,border-color .22s ease,box-shadow .22s ease}
        .question-card.active{border-color:rgba(69,194,255,.34);box-shadow:0 0 0 2px rgba(69,194,255,.18) inset}
        .question-card.flagged{border-color:rgba(244,179,61,.28)}
        .question-card.answered{box-shadow:0 0 0 1px rgba(43,214,176,.16) inset}
        .qmeta{display:flex;justify-content:space-between;gap:10px;color:var(--muted);font-size:.86rem;margin-bottom:12px}
        .question-card h3{font-size:1rem;line-height:1.7;margin-bottom:14px}
        .question-tools{display:flex;justify-content:space-between;gap:10px;align-items:center;margin-top:14px;flex-wrap:wrap}
        .opt{display:block;padding:13px;border:1px solid rgba(137,160,188,.16);border-radius:16px;margin:10px 0;background:rgba(255,255,255,.65);transition:border-color .18s ease, transform .18s ease}
        .opt:hover{border-color:rgba(69,194,255,.22);transform:translateX(2px)}
        input[type=text]{width:100%;padding:14px 15px;border-radius:16px;border:1px solid rgba(137,160,188,.18);background:rgba(255,255,255,.88);color:var(--text)}
        .flag-btn.active{background:rgba(244,179,61,.16);color:var(--gold)}
        .section-focus{animation:sectionPulse .55s ease}
        .exam-submit-footer{
            margin-top:18px;
            padding:18px 0 0;
        }
        #submit-modal{display:none;background:rgba(14,22,34,.55);align-items:center;justify-content:center;padding:24px;overflow:auto;z-index:2500}
        .modal{max-width:540px;width:100%;max-height:calc(100dvh - 48px);overflow:auto;padding:24px;background:var(--panel-strong)}
        .modal p{margin:14px 0 18px;color:var(--muted);line-height:1.7}
        #result-screen{
            display:none;
            flex-direction:column;
            align-items:flex-start;
            justify-content:flex-start;
            color:#eaf3ff;
            background:
                radial-gradient(circle at 12% 14%, rgba(61,168,255,.32), transparent 24rem),
                radial-gradient(circle at 88% 82%, rgba(135,87,255,.24), transparent 28rem),
                linear-gradient(130deg,#07192f 0%,#071126 45%,#100d2d 100%);
            overflow:auto;
            padding:24px
        }
        #result-screen::before{
            content:"";position:fixed;inset:0;pointer-events:none;opacity:.18;
            background-image:linear-gradient(rgba(145,210,255,.18) 1px,transparent 1px),linear-gradient(90deg,rgba(145,210,255,.18) 1px,transparent 1px);
            background-size:42px 42px;mask-image:linear-gradient(to bottom,black,transparent 82%)
        }
        #result-screen .shell{position:relative;z-index:1;width:min(1040px,100%);padding:34px 0 52px}
        #result-screen .panel,#result-screen .review,#result-screen .summary-chip{
            border-color:rgba(180,214,255,.18);background:rgba(7,20,39,.78);
            box-shadow:0 28px 80px rgba(0,0,0,.32),inset 0 1px 0 rgba(255,255,255,.06);backdrop-filter:blur(24px)
        }
        #result-screen .panel{padding:clamp(24px,5vw,48px)}
        #result-screen .panel h1,#result-screen .review h2{color:#eef6ff}
        #result-screen .muted{color:#a7b6cb}
        #result-screen .score{background:rgba(5,17,35,.74);border-color:rgba(78,230,255,.32);box-shadow:0 0 0 12px rgba(78,230,255,.04),0 0 44px rgba(78,230,255,.15)}
        #result-screen .score strong{color:#72f4c8;text-shadow:0 0 22px rgba(114,244,200,.34)}
        #result-screen .summary-chip{box-shadow:none}
        #result-screen .review-item{border-color:rgba(180,214,255,.12);background:rgba(255,255,255,.045)}
        #result-screen a.primary{color:#061426;background:linear-gradient(100deg,#4ee6ff,#8ca4ff);box-shadow:0 14px 26px rgba(78,183,255,.24)}
        #result-screen a.secondary{color:#ccecff;border-color:rgba(183,214,255,.14);background:rgba(255,255,255,.07)}
        .result-brand{display:inline-flex;align-items:center;gap:10px;margin-bottom:24px;color:#fff;font-family:'Space Grotesk',sans-serif;font-size:1.25rem;font-weight:700}
        .result-brand span{color:#4ee6ff}
        .result-brand small{margin-left:8px;color:#a7b6cb;font-family:'Plus Jakarta Sans',sans-serif;font-size:.64rem;letter-spacing:.16em}
        .theme-toggle{border:1px solid rgba(137,160,188,.2);border-radius:14px;padding:11px 14px;background:rgba(255,255,255,.7);color:var(--text);font:inherit;font-weight:700;cursor:pointer}
        html[data-theme='dark'] .theme-toggle{background:rgba(255,255,255,.07);border-color:var(--line);color:#eaf3ff}
        html:not([data-theme='dark']) #result-screen{color:#1f2a36;background:radial-gradient(circle at 12% 10%, rgba(40,148,239,.18), transparent 24rem),linear-gradient(145deg,#f7fbff 0%,#e9f3ff 100%)}
        html:not([data-theme='dark']) #result-screen::before{opacity:.08}
        html:not([data-theme='dark']) #result-screen .panel,html:not([data-theme='dark']) #result-screen .review,html:not([data-theme='dark']) #result-screen .summary-chip{border-color:rgba(137,160,188,.18);background:rgba(255,255,255,.88);box-shadow:var(--shadow)}
        html:not([data-theme='dark']) #result-screen .panel h1,html:not([data-theme='dark']) #result-screen .review h2{color:#1f2a36}
        html:not([data-theme='dark']) #result-screen .muted{color:#66768d}
        html:not([data-theme='dark']) #result-screen .score{background:rgba(255,255,255,.92);border-color:rgba(24,160,127,.2);box-shadow:0 0 0 12px rgba(35,166,213,.04),0 0 44px rgba(35,166,213,.12)}
        html:not([data-theme='dark']) #result-screen .score strong{color:#18a07f;text-shadow:none}
        html:not([data-theme='dark']) #result-screen .review-item{border-color:rgba(137,160,188,.14);background:rgba(248,251,255,.78)}
        html:not([data-theme='dark']) .result-brand{color:#10213b}
        html:not([data-theme='dark']) .result-brand small{color:#66768d}
        .result-actions{justify-content:center;margin-top:24px!important}
        #result-screen .result-action{
            display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:0 20px;border-radius:14px;font-size:.9rem;font-weight:800;letter-spacing:.01em;text-decoration:none;line-height:1;
            transition:transform .2s ease,box-shadow .2s ease,filter .2s ease
        }
        #result-screen .result-action:hover{transform:translateY(-2px)}
        #result-screen .dashboard-action{color:#dff7ff;border:1px solid rgba(117,218,255,.3);background:rgba(78,230,255,.09);box-shadow:inset 0 1px 0 rgba(255,255,255,.08)}
        #result-screen .dashboard-action:hover{background:rgba(78,230,255,.16);box-shadow:0 12px 26px rgba(32,183,235,.16)}
        #result-screen .exit-action{color:#061426;background:linear-gradient(100deg,#4ee6ff,#8ca4ff);box-shadow:0 14px 26px rgba(78,183,255,.28)}
        #result-screen .exit-action:hover{filter:brightness(1.06);box-shadow:0 18px 34px rgba(78,183,255,.38)}
        html:not([data-theme='dark']) #result-screen .dashboard-action{color:#14527c;border-color:rgba(22,127,224,.24);background:rgba(22,127,224,.08)}
        html:not([data-theme='dark']) #result-screen .exit-action{background:linear-gradient(100deg,#2cc7e8,#538cff)}
        .score{
            width:176px;height:176px;border-radius:50%;display:flex;flex-direction:column;justify-content:center;align-items:center;
            margin:18px auto;background:rgba(255,255,255,.92);border:10px solid rgba(24,160,127,.18)
        }
        .score strong{font-family:'Space Grotesk',sans-serif;font-size:2.8rem;color:var(--teal)}
        .summary-grid{grid-template-columns:repeat(auto-fit,minmax(180px,1fr))}
        .review{padding:22px;margin-top:18px}
        .review-item{border:1px solid rgba(137,160,188,.14);border-radius:16px;padding:14px;margin-top:12px;background:rgba(255,255,255,.72)}
        .badge{display:inline-flex;padding:6px 10px;border-radius:999px;font-size:.76rem;font-weight:700}
        .ok{background:var(--ok-soft);color:var(--teal)}
        .bad{background:var(--danger-soft);color:var(--danger)}
        #toast-stack{
            position:fixed;top:20px;right:20px;z-index:2600;display:grid;gap:12px;max-width:min(360px,calc(100vw - 30px))
        }
        .toast{
            padding:14px 16px;border-radius:18px;background:rgba(255,255,255,.98);border:1px solid rgba(137,160,188,.14);
            box-shadow:var(--shadow);transform:translateX(16px);opacity:0;animation:toastIn .28s ease forwards
        }
        .toast strong{display:block;margin-bottom:5px}
        .toast p{color:var(--muted);font-size:.9rem;line-height:1.55}
        .toast.danger{border-color:rgba(255,95,127,.3)}
        .toast.info{border-color:rgba(69,194,255,.26)}
        .toast.warn{border-color:rgba(244,179,61,.28)}
        @keyframes scanMove{0%{transform:translateY(0)}100%{transform:translateY(130px)}}
        @keyframes shakeX{0%,100%{transform:translateX(0)}25%{transform:translateX(-8px)}75%{transform:translateX(8px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @keyframes toastIn{to{opacity:1;transform:translateX(0)}}
        @keyframes sectionPulse{0%{transform:translateY(4px)}60%{transform:translateY(0)}100%{transform:translateY(0)}}
        @keyframes cardReveal{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @media(max-width:1280px){
            #sidebar{width:340px;min-width:340px}
            #exam-shell{grid-template-columns:250px minmax(0,1fr)}
        }
        @media(max-width:1120px){
            body{display:block;overflow:auto;height:auto}
            .gateway-shell{grid-template-columns:1fr}
            .gateway-side{border-left:none;border-top:1px solid rgba(143,177,214,.14)}
            .gateway-shell{max-height:none}
            .gateway-main,.gateway-side{overflow:visible;max-height:none}
            #main-wrapper{display:block;height:auto;min-height:100vh;overflow:visible}
            #top-nav{position:static}
            #sidebar,#exam-shell,#top-nav{position:static}
            #sidebar{width:100%;min-width:0;max-height:none}
            #exam-shell{grid-template-columns:1fr;height:auto;overflow:visible}
            #progress-rail{height:auto;position:static;border-right:none;border-bottom:1px solid rgba(143,177,214,.1);overflow:visible}
            #exam-paper{height:auto;overflow:visible}
        }
        @media(max-width:760px){
            #permission-shield{padding:16px}
            .gateway-main,.gateway-side,#sidebar,#exam-paper{padding:18px}
            #top-nav{grid-template-columns:1fr;gap:12px}
            .top-bar-grid,.status-ribbon,.trust-grid,.summary-grid,.progress-grid{grid-template-columns:1fr}
            .timer-wrap{justify-content:center}
            .section-head,.question-tools{flex-direction:column;align-items:flex-start}
            .actions button,.section-actions button{width:100%}
            .progress-grid{grid-template-columns:repeat(4,minmax(0,1fr))}
        }
        @media(max-width:480px){
            #permission-shield{padding:10px}
            .gateway-main,.gateway-side,#sidebar,#exam-paper{padding:14px}
            .gateway-main h1{font-size:1.8rem}
            .gateway-kpis{grid-template-columns:1fr}
            .camera-stage{min-height:190px}
            .top-bar-grid{gap:8px}
            .timer-wrap{width:100%}
            .timer-wrap .timer{width:100%;text-align:center}
            .question-card{padding:16px}
            .option{min-height:46px}
            .progress-grid{grid-template-columns:repeat(3,minmax(0,1fr))}
            #result-screen{padding:14px}
            #result-screen .shell{padding:16px 0 34px}
            .result-brand{font-size:1.1rem}
            .result-brand small{display:none}
        }
        @media (prefers-reduced-motion: reduce) {
            *, body, body.page-ready, body.page-exit { transition:none !important; animation:none !important; transform:none !important; scroll-behavior:auto !important; }
        }
    </style>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
    <body onclick="startAudio()">
    <div id="toast-stack"></div>

    <div id="permission-shield">
        <div class="gateway-shell">
            <div class="gateway-main">
                <div class="eyebrow">Secure Exam Gateway</div>
                <h1>{{ exam_payload.paper_title }}</h1>
                <p class="lead">Enable camera and microphone, confirm your environment is stable, and verify your face before starting your Year {{ year_group }} assessment. The older workflow stays intact, but this checklist helps you enter cleanly and safely.</p>
                <div class="gateway-kpis">
                    <div class="kpi-card">
                        <div class="kpi-label">Duration</div>
                        <div class="kpi-value">{{ exam_settings.exam_duration_minutes }} min</div>
                    </div>
                    <div class="kpi-card">
                        <div class="kpi-label">Question Mix</div>
                        <div class="kpi-value">30 Questions</div>
                    </div>
                    <div class="kpi-card">
                        <div class="kpi-label">Reconnect Guard</div>
                        <div class="kpi-value">Ready</div>
                    </div>
                </div>
                <div class="face-verify-shell">
                    <div class="eyebrow" style="margin-bottom:10px;">Face Verification</div>
                    <div id="scan-stage" class="scan-stage">
                        <div class="scan-line"></div>
                        <div class="scan-face">O</div>
                    </div>
                    <p id="face-status" class="scan-caption">Face verification pending. Keep your face centered and use similar lighting to the saved profile photo.</p>
                </div>
                <div class="check-card" style="margin-top:22px;">
                    <div class="eyebrow" style="margin-bottom:10px;">Readiness Checklist</div>
                    <div class="readiness-grid">
                        <div class="check-row">
                            <div class="check-copy"><strong>Camera working</strong><span>Live frame must be available before the exam opens.</span></div>
                            <div class="check-status pending" id="check-camera">Pending</div>
                        </div>
                        <div class="check-row">
                            <div class="check-copy"><strong>Microphone working</strong><span>Audio access is checked when device permissions are granted.</span></div>
                            <div class="check-status pending" id="check-mic">Pending</div>
                        </div>
                        <div class="check-row">
                            <div class="check-copy"><strong>Face verified</strong><span>Your live image must match the saved profile photo.</span></div>
                            <div class="check-status pending" id="check-face">Pending</div>
                        </div>
                        <div class="check-row">
                            <div class="check-copy"><strong>Internet stable</strong><span>Live online status is monitored before and during the paper.</span></div>
                            <div class="check-status pending" id="check-network">Pending</div>
                        </div>
                        <div class="check-row">
                            <div class="check-copy"><strong>Fullscreen enabled</strong><span>Use the secure full-view mode before starting the paper.</span></div>
                            <div class="check-status pending" id="check-fullscreen">Pending</div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="gateway-side">
                <div class="sidebar-card">
                    <div class="sidebar-title">Environment Notes</div>
                    <p class="muted">Stay centered in frame, keep the microphone active, avoid switching tabs, and use fullscreen mode throughout the attempt.</p>
                </div>
                <div class="sidebar-card">
                    <div class="sidebar-title">Resume Support</div>
                    <p class="muted" id="resume-copy">If the page refreshes accidentally, your local answers and timer can be restored when the active attempt is still open.</p>
                </div>
                <div class="sidebar-card">
                    <div class="sidebar-title">Start Controls</div>
                    <div class="actions" style="margin-top:10px;">
                        <button id="enable-media-btn" class="secondary" type="button" onclick="initMedia()">Enable Camera And Mic</button>
                        <button id="fullscreen-btn" class="secondary" type="button" onclick="enableFullscreen()">Enable Fullscreen</button>
                        <button id="verify-face-btn" class="primary" type="button" onclick="verifyFaceAndStart()">Verify Face And Start</button>
                        <button id="resume-btn" class="secondary" type="button" onclick="resumeSavedAttempt()" style="display:none;">Resume Saved Attempt</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="sidebar">
        <div class="sidebar-card">
            <div class="sidebar-title">Live AI Monitoring</div>
            <div id="webcam-shell">
                <video id="webcam" autoplay playsinline muted></video>
                <div class="camera-overlay"></div>
            </div>
        </div>
        <div class="status-ribbon">
            <div class="status-card">
                <strong>Mic State</strong>
                <div class="status-copy" id="mic-status-copy">Waiting for microphone access.</div>
            </div>
            <div class="status-card">
                <strong>Exam State</strong>
                <div class="status-copy" id="exam-state-copy">Readiness gate is still active.</div>
            </div>
        </div>
        <div class="sidebar-card">
            <div class="sidebar-title">Environmental Audio</div>
            <div class="meter"><div id="audio-level"></div></div>
        </div>
        <div class="sidebar-card">
            <div class="sidebar-title">Live Trust Meter</div>
            <div class="trust-grid">
                <div class="trust-badge" id="trust-badge"><span id="trust-score-value">0</span></div>
                <div class="trust-copy">
                    <strong id="trust-label">Low Risk</strong>
                    <p id="trust-description">No major proctoring concerns so far. Maintain a stable frame, active mic, and fullscreen focus.</p>
                </div>
            </div>
        </div>
        <div class="sidebar-card">
            <div class="sidebar-title">Violation Score</div>
            <div class="violation-score">
                <div style="font-size:.78rem;color:#c7d1de">Score against auto-submit threshold</div>
                <strong id="violation-score-value">0 / 20</strong>
                <div id="violation-score-note" style="font-size:.82rem;color:#c7d1de;margin-top:4px">Updated live after each violation.</div>
            </div>
        </div>
        <div class="sidebar-card">
            <div class="sidebar-title">Monitoring Log</div>
            <div id="status-log"></div>
        </div>
    </div>

    <div id="main-wrapper">
        <div id="top-nav">
            <div class="top-bar-grid">
                <div class="top-bar-card"><span>Student</span><strong>{{ student_name }}</strong></div>
                <div class="top-bar-card"><span>Roll Number</span><strong>{{ student_id }}</strong></div>
                <div class="top-bar-card"><span>Year Group</span><strong>Year {{ year_group }}</strong></div>
            </div>
            <div class="timer-wrap">
                <div class="timer-ring">
                    <svg viewBox="0 0 64 64">
                        <circle class="bg" cx="32" cy="32" r="26"></circle>
                        <circle class="progress" id="timer-progress" cx="32" cy="32" r="26"></circle>
                    </svg>
                </div>
                <div class="timer-meta">
                    <strong id="timer">60:00</strong>
                    <span id="timer-note">Secure timer is running.</span>
                </div>
            </div>
            <div class="actions" style="justify-content:flex-end;">
                <button class="theme-toggle" type="button" onclick="toggleTheme()">Dark Mode</button>
                <button class="secondary" type="button" onclick="enableFullscreen()">Fullscreen</button>
                <button class="primary" id="submit-btn" onclick="confirmSubmit()">Submit Exam</button>
            </div>
        </div>
        <div id="exam-shell">
            <div id="progress-rail">
                <div class="rail-card">
                    <div class="rail-title">Progress Rail</div>
                    <div class="flag-summary"><span>Answered: <strong id="answered-count">0</strong></span><span>Flagged: <strong id="flagged-count">0</strong></span></div>
                    <div class="progress-grid" id="progress-grid" style="margin-top:14px;"></div>
                </div>
                <div class="rail-card">
                    <div class="rail-title">Section Navigator</div>
                    <div id="section-nav-links"></div>
                </div>
                <div class="rail-card">
                    <div class="rail-title">Reconnect Recovery</div>
                    <p class="muted" id="restore-summary">No saved answers detected yet.</p>
                </div>
            </div>
            <div id="exam-paper">
                <div class="shell">
                    <div class="panel">
                        <h1>{{ exam_payload.paper_title }}</h1>
                        <p class="muted">Questions remain shuffled for your student ID. The new layout adds section navigation, progress visibility, and reconnect support without removing the original exam flow.</p>
                        <div class="pattern">
                            <div class="chip"><strong>Section A</strong><div class="muted">10 MCQs | 20 marks</div></div>
                            <div class="chip"><strong>Section B</strong><div class="muted">10 True / False | 20 marks</div></div>
                            <div class="chip"><strong>Section C</strong><div class="muted">10 Fill Blanks | 10 marks</div></div>
                        </div>
                    </div>
                    <div id="questions-container"></div>
                    <div class="actions exam-submit-footer"><button class="primary" onclick="confirmSubmit()">Submit Exam</button></div>
                </div>
            </div>
        </div>
    </div>

    <div id="submit-modal">
        <div class="modal">
            <h2>Confirm Submission</h2>
            <p>Your answers will be graded immediately and you will still receive section-wise analysis with correct answers, explanations, and risk summary after submission.</p>
            <div class="actions" style="justify-content:center;">
                <button class="primary" id="confirm-submit-btn" onclick="finalProcess()">Yes, Submit</button>
                <button class="secondary" onclick="closeModal()">Cancel</button>
            </div>
        </div>
    </div>

    <div id="result-screen">
        <div class="shell">
            <div class="result-brand">Proctor<span>X</span><small>ASSESSMENT REPORT</small><button class="theme-toggle" type="button" onclick="toggleTheme()">Dark Mode</button></div>
            <div class="panel" style="text-align:center">
                <h1 id="result-title">Assessment Submitted</h1>
                <div class="score"><strong id="final-score">0</strong><span id="score-total">/ 50</span></div>
                <p class="muted" id="result-risk-copy">Section-wise performance and question analysis are shown below.</p>
                <div class="summary-grid" id="section-summary"></div>
                <div class="summary-grid" id="suggestion-summary" style="margin-top:16px;"></div>
                <div class="actions result-actions">
                    <a class="result-action dashboard-action" href="{{ url_for('student_dashboard') }}">Back to Dashboard</a>
                    <a class="result-action exit-action" href="{{ url_for('logout') }}">Exit Portal</a>
                </div>
            </div>
            <div id="analysis-container"></div>
        </div>
    </div>

    <script>
        function applyTheme(theme) {
            document.documentElement.dataset.theme = theme;
            localStorage.setItem('portal-theme', theme);
            document.querySelectorAll('.theme-toggle').forEach(button => {
                button.textContent = theme === 'dark' ? 'Light Mode' : 'Dark Mode';
            });
        }

        function toggleTheme() {
            applyTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark');
        }

        const socket = window.io ? io() : {
            emit() {},
            on() {},
            disconnect() {}
        };
        if (!window.io) {
            console.warn('Socket.IO client was not available. Proctoring events will be disabled, but the exam UI will still work.');
        }
        applyTheme(document.documentElement.dataset.theme || 'light');
        const examPayload = {{ exam_payload|tojson }};
        const resumeState = {{ resume_state|tojson }};
        const studentInfo = "{{ student_id }} - {{ student_name }}";
        const studentId = "{{ student_id }}";
        const studentName = "{{ student_name }}";
        const yearGroup = {{ year_group }};
        const examDurationMinutes = {{ exam_settings.exam_duration_minutes or 60 }};
        const storageKey = `exam-state:${studentId}:${yearGroup}`;
        const totalDurationSeconds = examDurationMinutes * 60;
        const ringRadius = 26;
        const ringCircumference = 2 * Math.PI * ringRadius;

        const video = document.getElementById('webcam');
        const log = document.getElementById('status-log');
        const audioBar = document.getElementById('audio-level');
        const timerDisplay = document.getElementById('timer');
        const timerProgress = document.getElementById('timer-progress');
        const timerNote = document.getElementById('timer-note');
        const faceStatus = document.getElementById('face-status');
        const verifyFaceBtn = document.getElementById('verify-face-btn');
        const enableMediaBtn = document.getElementById('enable-media-btn');
        const fullscreenBtn = document.getElementById('fullscreen-btn');
        const resumeBtn = document.getElementById('resume-btn');
        const violationScoreValue = document.getElementById('violation-score-value');
        const violationScoreNote = document.getElementById('violation-score-note');
        const trustBadge = document.getElementById('trust-badge');
        const trustScoreValue = document.getElementById('trust-score-value');
        const trustLabel = document.getElementById('trust-label');
        const trustDescription = document.getElementById('trust-description');
        const progressGrid = document.getElementById('progress-grid');
        const answeredCount = document.getElementById('answered-count');
        const flaggedCount = document.getElementById('flagged-count');
        const sectionNavLinks = document.getElementById('section-nav-links');
        const restoreSummary = document.getElementById('restore-summary');
        const micStatusCopy = document.getElementById('mic-status-copy');
        const examStateCopy = document.getElementById('exam-state-copy');
        const scanStage = document.getElementById('scan-stage');
        const toastStack = document.getElementById('toast-stack');

        timerProgress.style.strokeDasharray = `${ringCircumference} ${ringCircumference}`;
        timerProgress.style.strokeDashoffset = ringCircumference;

        let audioCtx;
        let streamRef = null;
        let timeLeft = totalDurationSeconds;
        let timerStarted = false;
        let examSubmitted = false;
        let submitting = false;
        let aiInterval = null;
        let liveStatusInterval = null;
        let persistInterval = null;
        let timerInterval = null;
        let lastAudioEmitAt = 0;
        let lastTabSwitchEmitAt = 0;
        let latestEvidenceFrame = '';
        let faceVerified = false;
        let faceMatchScore = 0;
        let localViolationCount = 0;
        let localViolationScore = 0;
        let autoSubmitTriggered = false;
        let autoSubmittedByViolations = false;
        let lastActivityAt = Date.now();
        let afkReported = false;
        let isResuming = false;
        let activeQuestionId = '';
        let currentRiskLabel = 'Low';
        let currentRiskScore = 0;
        let questionState = {};
        let lastAnnouncementAt = '';

        const esc = (s) => String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');

        function defaultQuestionState() {
            const state = {};
            examPayload.sections.forEach(section => section.questions.forEach(question => {
                state[question.id] = { answered: false, flagged: false, value: '' };
            }));
            return state;
        }

        function safeParseStorage() {
            try {
                const raw = localStorage.getItem(storageKey);
                return raw ? JSON.parse(raw) : null;
            } catch (error) {
                return null;
            }
        }

        function hasSavedAttempt() {
            const saved = safeParseStorage();
            return !!(saved && saved.answers && Object.keys(saved.answers).length);
        }

        function setChecklistStatus(id, status, label) {
            const el = document.getElementById(id);
            if (!el) return;
            el.className = `check-status ${status}`;
            el.textContent = label;
        }

        function updateNetworkStatus() {
            const online = navigator.onLine;
            setChecklistStatus('check-network', online ? 'ok' : 'error', online ? 'Stable' : 'Offline');
            if (!online && timerStarted && !examSubmitted) {
                showToast('Connection warning', 'Your network dropped. Answers are still being saved locally for resume support.', 'warn');
            }
        }

        function supportsFullscreen() {
            const root = document.documentElement;
            return !!(root.requestFullscreen || root.webkitRequestFullscreen || root.mozRequestFullScreen || root.msRequestFullscreen);
        }

        function isFullscreenActive() {
            return !!(document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement);
        }

        function updateFullscreenStatus() {
            const full = isFullscreenActive() || !supportsFullscreen();
            setChecklistStatus('check-fullscreen', full ? 'ok' : 'pending', full ? 'Enabled' : 'Pending');
        }

        function updateMediaChecklist() {
            setChecklistStatus('check-camera', video.videoWidth ? 'ok' : 'pending', video.videoWidth ? 'Ready' : 'Pending');
            setChecklistStatus('check-mic', streamRef ? 'ok' : 'pending', streamRef ? 'Ready' : 'Pending');
            setChecklistStatus('check-face', faceVerified ? 'ok' : 'pending', faceVerified ? 'Verified' : 'Pending');
        }

        function readinessSatisfied() {
            const fullscreenReady = isFullscreenActive() || !supportsFullscreen();
            return !!(streamRef && video.videoWidth && navigator.onLine && fullscreenReady && faceVerified);
        }

        function enableFullscreen() {
            const root = document.documentElement;
            const request = root.requestFullscreen || root.webkitRequestFullscreen || root.mozRequestFullScreen || root.msRequestFullscreen;
            if (!isFullscreenActive() && request) {
                try {
                    return Promise.resolve(request.call(root)).catch(() => {
                        showToast('Fullscreen required', 'Enable fullscreen mode before starting the secure exam.', 'warn');
                    });
                } catch (error) {
                    showToast('Fullscreen required', 'Enable fullscreen mode before starting the secure exam.', 'warn');
                    return Promise.resolve();
                }
            }
            if (!request) {
                showToast('Fullscreen unavailable', 'This browser does not support fullscreen. Keep the exam tab open and focused.', 'warn');
            }
            updateFullscreenStatus();
            return Promise.resolve();
        }

        function showToast(title, message, tone = 'info', sticky = false) {
            const toast = document.createElement('div');
            toast.className = `toast ${tone}`;
            toast.innerHTML = `<strong>${esc(title)}</strong><p>${esc(message)}</p>`;
            toastStack.prepend(toast);
            if (!sticky) {
                setTimeout(() => {
                    toast.style.opacity = '0';
                    toast.style.transform = 'translateX(16px)';
                    setTimeout(() => toast.remove(), 220);
                }, 3200);
            }
            return toast;
        }

        function addLog(msg) {
            const item = document.createElement('div');
            item.className = 'alert-item';
            item.innerText = `${new Date().toLocaleTimeString()}: ${msg}`;
            log.prepend(item);
        }

        function flashAlert(msg) {
            showToast('Proctoring alert', msg, 'danger');
        }

        function startAudio() {
            if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume();
        }

        function renderProgressRail() {
            const items = [];
            let questionNumber = 1;
            examPayload.sections.forEach(section => section.questions.forEach(question => {
                const state = questionState[question.id] || { answered: false, flagged: false };
                items.push(`
                    <button type="button" class="progress-pill ${state.answered ? 'answered' : ''} ${state.flagged ? 'flagged' : ''} ${activeQuestionId === question.id ? 'active' : ''}" onclick="jumpToQuestion('${question.id}')">${questionNumber}</button>
                `);
                questionNumber += 1;
            }));
            progressGrid.innerHTML = items.join('');
            answeredCount.textContent = Object.values(questionState).filter(item => item.answered).length;
            flaggedCount.textContent = Object.values(questionState).filter(item => item.flagged).length;
        }

        function renderSectionNav() {
            sectionNavLinks.innerHTML = examPayload.sections.map((section, index) => `
                <button type="button" class="rail-section-link" onclick="jumpToSection('${section.id}')">
                    ${esc(section.title)}${index < examPayload.sections.length - 1 ? ` (${section.questions.length})` : ` (${section.questions.length})`}
                </button>
            `).join('');
        }

        function updateQuestionVisual(questionId) {
            const state = questionState[questionId] || { answered: false, flagged: false };
            const card = document.getElementById(`card-${questionId}`);
            if (!card) return;
            card.classList.toggle('answered', !!state.answered);
            card.classList.toggle('flagged', !!state.flagged);
            card.classList.toggle('active', activeQuestionId === questionId);
            const flagButton = card.querySelector('.flag-btn');
            if (flagButton) {
                flagButton.classList.toggle('active', !!state.flagged);
                flagButton.textContent = state.flagged ? 'Flagged For Review' : 'Flag For Review';
            }
        }

        function updateAllQuestionVisuals() {
            Object.keys(questionState).forEach(updateQuestionVisual);
            renderProgressRail();
        }

        function collectAnswers() {
            const answers = {};
            examPayload.sections.forEach(section => section.questions.forEach(question => {
                if (question.type === 'fill_blank') {
                    answers[question.id] = (document.getElementById(question.id)?.value || '').trim();
                } else {
                    answers[question.id] = document.querySelector(`input[name="${question.id}"]:checked`)?.value || '';
                }
            }));
            return answers;
        }

        function syncQuestionStateFromDom() {
            const answers = collectAnswers();
            Object.keys(questionState).forEach(questionId => {
                const value = answers[questionId] || '';
                questionState[questionId] = {
                    ...questionState[questionId],
                    value,
                    answered: !!String(value).trim()
                };
            });
            updateAllQuestionVisuals();
        }

        function jumpToQuestion(questionId) {
            activeQuestionId = questionId;
            updateAllQuestionVisuals();
            const card = document.getElementById(`card-${questionId}`);
            if (!card) return;
            card.scrollIntoView({ behavior: 'smooth', block: 'center' });
            card.classList.remove('section-focus');
            setTimeout(() => card.classList.add('section-focus'), 0);
        }

        function jumpToSection(sectionId) {
            const section = document.getElementById(`section-${sectionId}`);
            if (!section) return;
            section.scrollIntoView({ behavior: 'smooth', block: 'start' });
            section.classList.remove('section-focus');
            setTimeout(() => section.classList.add('section-focus'), 0);
        }

        function navigateSection(direction, currentSectionId) {
            const index = examPayload.sections.findIndex(section => section.id === currentSectionId);
            if (index === -1) return;
            const next = examPayload.sections[index + direction];
            if (next) jumpToSection(next.id);
        }

        function toggleFlag(questionId) {
            questionState[questionId] = {
                ...questionState[questionId],
                flagged: !questionState[questionId]?.flagged
            };
            updateQuestionVisual(questionId);
            renderProgressRail();
            persistExamState();
        }

        function renderExam() {
            let questionNumber = 1;
            const html = examPayload.sections.map((section, sectionIndex) => {
                const navButtons = [];
                if (sectionIndex > 0) navButtons.push(`<button type="button" class="secondary nav-mini" onclick="navigateSection(-1, '${section.id}')">Previous Section</button>`);
                if (sectionIndex < examPayload.sections.length - 1) navButtons.push(`<button type="button" class="secondary nav-mini" onclick="navigateSection(1, '${section.id}')">Next Section</button>`);
                const questions = section.questions.map(question => {
                    const number = questionNumber++;
                    return `
                        <div class="question-card" id="card-${question.id}" data-question-id="${question.id}">
                            <div class="qmeta"><span>Question ${number}</span><span>${question.marks} mark(s)</span></div>
                            <h3>${esc(question.question)}</h3>
                            ${question.type === 'fill_blank'
                                ? `<input type="text" id="${question.id}" placeholder="Type a single-word answer" oninput="handleAnswerChange('${question.id}')">`
                                : question.options.map(option => `<label class="opt"><input type="radio" name="${question.id}" value="${esc(option)}" onchange="handleAnswerChange('${question.id}')"> ${esc(option)}</label>`).join('')}
                            <div class="question-tools">
                                <button type="button" class="secondary flag-btn" onclick="toggleFlag('${question.id}')">Flag For Review</button>
                                <div class="muted">Use the progress rail to jump between questions and flagged items.</div>
                            </div>
                        </div>
                    `;
                }).join('');

                return `
                    <section class="section-card" id="section-${section.id}" style="animation-delay:${sectionIndex * 80}ms;">
                        <div class="section-head">
                            <div>
                                <h2>${esc(section.title)}</h2>
                                <p class="section-copy">${section.marks_per_question} mark(s) each. Use the navigator and flags to review before submission.</p>
                            </div>
                            <div class="section-actions">${navButtons.join('')}</div>
                        </div>
                        <div class="question-stack">${questions}</div>
                    </section>
                `;
            }).join('');
            document.getElementById('questions-container').innerHTML = html;
            attachQuestionFocusTracking();
            renderSectionNav();
            updateAllQuestionVisuals();
        }

        function attachQuestionFocusTracking() {
            document.querySelectorAll('.question-card input').forEach(input => {
                input.addEventListener('focus', event => {
                    const card = event.target.closest('.question-card');
                    if (!card) return;
                    activeQuestionId = card.dataset.questionId || '';
                    updateAllQuestionVisuals();
                });
            });
        }

        function handleAnswerChange(questionId) {
            syncQuestionStateFromDom();
            activeQuestionId = questionId;
            updateAllQuestionVisuals();
            persistExamState();
        }

        function updateTimerRing() {
            const ratio = Math.max(0, Math.min(1, timeLeft / totalDurationSeconds));
            timerProgress.style.strokeDashoffset = ringCircumference - (ratio * ringCircumference);
            timerProgress.style.stroke = ratio > 0.35 ? 'var(--gold)' : ratio > 0.15 ? 'var(--danger)' : '#ff305b';
            timerNote.textContent = ratio > 0.35 ? 'Secure timer is running.' : ratio > 0.15 ? 'Time is running low.' : 'Final countdown in progress.';
        }

        function updateTrustMeter(score = 0, level = 'Low') {
            currentRiskScore = Number(score || 0);
            currentRiskLabel = level || 'Low';
            const capped = Math.max(0, Math.min(100, currentRiskScore));
            trustScoreValue.textContent = capped;
            trustBadge.style.background = `conic-gradient(${level === 'High' ? 'var(--danger)' : level === 'Medium' ? 'var(--gold)' : 'var(--teal)'} ${capped / 100}turn, rgba(255,255,255,.06) 0turn)`;
            trustLabel.textContent = `${currentRiskLabel} Risk`;
            if (currentRiskLabel === 'High') {
                trustDescription.textContent = 'Multiple or repeated violations are now pushing this attempt into a high-risk band. A clean recovery is needed immediately.';
            } else if (currentRiskLabel === 'Medium') {
                trustDescription.textContent = 'Some suspicious signals were detected. Stay centered, quiet, and in fullscreen to avoid escalation.';
            } else {
                trustDescription.textContent = 'No major proctoring concerns so far. Maintain a stable frame, active mic, and fullscreen focus.';
            }
        }

        function updateViolationScore(score, threshold = 20) {
            localViolationScore = score;
            violationScoreValue.innerText = `${score} / ${threshold}`;
            violationScoreNote.innerText = score > threshold ? 'Violation threshold crossed. Auto-submitting exam.' : 'Updated live after each violation.';
            let level = 'Low';
            if (score >= 12) level = 'High';
            else if (score >= 5) level = 'Medium';
            updateTrustMeter(score * 4, level);
        }

        function persistExamState() {
            if (examSubmitted) return;
            const payload = {
                saved_at: new Date().toISOString(),
                answers: collectAnswers(),
                flags: Object.fromEntries(Object.entries(questionState).map(([key, value]) => [key, !!value.flagged])),
                time_left: timeLeft,
                face_verified: faceVerified,
                face_match_score: faceMatchScore,
                violation_count: localViolationCount,
                violation_score_total: localViolationScore,
                risk_score: currentRiskScore,
                risk_level: currentRiskLabel
            };
            localStorage.setItem(storageKey, JSON.stringify(payload));
            restoreSummary.textContent = `Saved locally at ${new Date(payload.saved_at).toLocaleTimeString()} with ${Object.values(payload.answers).filter(value => String(value || '').trim()).length} answered question(s).`;
            if (hasSavedAttempt()) {
                resumeBtn.style.display = 'inline-flex';
                document.getElementById('resume-copy').textContent = 'A saved attempt was detected. You can resume the local answer state after media and verification checks.';
            }
        }

        function clearPersistedExamState() {
            localStorage.removeItem(storageKey);
            restoreSummary.textContent = 'No saved answers detected yet.';
            resumeBtn.style.display = 'none';
            document.getElementById('resume-copy').textContent = 'If the page refreshes accidentally, your local answers and timer can be restored when the active attempt is still open.';
        }

        function restoreFromSavedState(saved) {
            if (!saved) return;
            const answers = saved.answers || {};
            const flags = saved.flags || {};
            Object.keys(questionState).forEach(questionId => {
                const question = document.getElementById(questionId);
                if (question) {
                    question.value = answers[questionId] || '';
                }
                document.querySelectorAll(`input[name="${questionId}"]`).forEach(input => {
                    input.checked = input.value === (answers[questionId] || '');
                });
                questionState[questionId] = {
                    ...questionState[questionId],
                    value: answers[questionId] || '',
                    answered: !!String(answers[questionId] || '').trim(),
                    flagged: !!flags[questionId]
                };
            });
            timeLeft = Math.min(totalDurationSeconds, Math.max(0, Number(saved.time_left || totalDurationSeconds)));
            localViolationCount = Number(saved.violation_count || 0);
            updateViolationScore(Number(saved.violation_score_total || 0), 20);
            updateTrustMeter(Number(saved.risk_score || 0), saved.risk_level || 'Low');
            faceVerified = !!saved.face_verified;
            faceMatchScore = Number(saved.face_match_score || 0);
            updateMediaChecklist();
            updateTimerRing();
            syncQuestionStateFromDom();
            addLog('Saved attempt data restored after reconnect.');
            showToast('Attempt restored', 'Your local answers and timer were restored after reconnect.', 'info');
        }

        function resumeSavedAttempt() {
            const saved = safeParseStorage();
            if (!saved) {
                showToast('Nothing to resume', 'No saved local exam state was found for this attempt.', 'warn');
                return;
            }
            if (!streamRef) {
                showToast('Media needed first', 'Enable camera and microphone before restoring the attempt view.', 'warn');
                return;
            }
            isResuming = true;
            showToast('Resume armed', 'Finish face verification to restore the saved attempt state.', 'info');
        }

        function initSavedAttemptHint() {
            if (hasSavedAttempt()) {
                resumeBtn.style.display = 'inline-flex';
                const saved = safeParseStorage();
                restoreSummary.textContent = `Saved local state found from ${new Date(saved.saved_at).toLocaleTimeString()}.`;
                document.getElementById('resume-copy').textContent = 'A saved attempt was detected. You can resume the local answer state after media and verification checks.';
            }
            if (resumeState.active && resumeState.remaining_seconds > 0) {
                document.getElementById('resume-copy').textContent = 'The server also sees an active attempt. Resume support is ready if the local answer state exists.';
            }
        }

        function resetAttemptUI() {
            localViolationCount = Number(resumeState.violation_count || 0);
            localViolationScore = Number(resumeState.violation_score_total || 0);
            autoSubmitTriggered = false;
            autoSubmittedByViolations = false;
            afkReported = false;
            lastActivityAt = Date.now();
            updateViolationScore(localViolationScore, 20);
            updateTrustMeter(Number(resumeState.risk_score || 0), resumeState.risk_level || 'Low');
            if (log) log.innerHTML = '';
            examStateCopy.textContent = 'Monitoring is armed. Stay in fullscreen and keep your face visible.';
        }

        function markActivity() {
            lastActivityAt = Date.now();
            afkReported = false;
        }

        function confirmSubmit() {
            if (!examSubmitted && !submitting) document.getElementById('submit-modal').style.display = 'flex';
        }

        function closeModal() {
            document.getElementById('submit-modal').style.display = 'none';
        }

        function triggerAutoSubmit(threshold) {
            if (autoSubmitTriggered || examSubmitted || submitting) return;
            autoSubmitTriggered = true;
            autoSubmittedByViolations = true;
            violationScoreNote.innerText = `Violation score crossed ${threshold}. Auto-submitting exam now.`;
            closeModal();
            setTimeout(() => finalProcess({ forced: true }), 0);
        }

        async function finalProcess(options = {}) {
            if (examSubmitted || submitting) return;
            submitting = true;
            document.getElementById('confirm-submit-btn').innerText = options.forced ? 'Auto Submitting...' : 'Submitting...';
            try {
                const res = await fetch('/submit_exam', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year_group: yearGroup, answers: collectAnswers() })
                });
                const raw = await res.text();
                let data = {};
                try {
                    data = raw ? JSON.parse(raw) : {};
                } catch (parseError) {
                    throw new Error(raw && raw.includes('<!DOCTYPE') ? 'The server returned an unexpected HTML error page.' : (raw || 'Submission failed'));
                }
                if (!res.ok || data.status !== 'success') throw new Error(data.message || 'Submission failed');
                examSubmitted = true;
                clearPersistedExamState();
                closeModal();
                showResult(data.result);
            } catch (err) {
                showToast('Submission failed', `Could not submit the exam: ${err.message}`, 'danger');
            } finally {
                submitting = false;
                document.getElementById('confirm-submit-btn').innerText = 'Yes, Submit';
            }
        }

        function showResult(result) {
            const sectionResults = Array.isArray(result.section_results) ? result.section_results : [];
            const totalScore = Number.isFinite(Number(result.total_score)) ? Number(result.total_score) : 0;
            const totalMarks = Number.isFinite(Number(result.total_marks)) ? Number(result.total_marks) : 0;
            const riskScore = Number.isFinite(Number(result.risk_score)) ? Number(result.risk_score) : 0;
            const riskLevel = result.risk_level || 'Low';
            const resultScreen = document.getElementById('result-screen');
            resultScreen.style.display = 'flex';
            document.getElementById('result-title').innerText = autoSubmittedByViolations ? 'Exam Auto-Submitted' : 'Assessment Submitted';
            document.getElementById('final-score').innerText = totalScore;
            document.getElementById('score-total').innerText = `/ ${totalMarks}`;
            document.getElementById('section-summary').innerHTML = sectionResults.length
                ? sectionResults.map(section => `<div class="summary-chip"><strong>${esc(section.title)}</strong><div class="muted">${section.score} / ${section.total}</div></div>`).join('')
                : `<div class="summary-chip"><strong>No section data returned</strong><div class="muted">The submission completed, but the detailed section analysis was not available.</div></div>`;
            document.getElementById('result-risk-copy').innerText = `${autoSubmittedByViolations ? 'The exam was auto-submitted because the violation score crossed the allowed threshold. ' : ''}Cheating risk score: ${riskScore} (${riskLevel}). Section-wise performance and question analysis are shown below.`;
            document.getElementById('suggestion-summary').innerHTML = sectionResults.filter(section => section.total && ((section.score / section.total) * 100) < 65).map(section => `<div class="summary-chip"><strong>${esc(section.title)}</strong><div class="muted">Recommended practice: revise this section and solve more targeted questions.</div></div>`).join('');
            document.getElementById('analysis-container').innerHTML = sectionResults.length
                ? sectionResults.map(section => `<div class="review"><h2>${esc(section.title)}</h2><p class="muted">${section.score} / ${section.total}</p>${(section.questions || []).map(question => `<div class="review-item"><div style="display:flex;justify-content:space-between;gap:12px"><strong>Q${question.number}. ${esc(question.question)}</strong><span class="badge ${question.is_correct ? 'ok' : 'bad'}">${question.is_correct ? 'Correct' : 'Review'}</span></div><p class="muted"><strong>Your Answer:</strong> ${esc(question.user_answer)}</p><p class="muted"><strong>Correct Answer:</strong> ${esc(question.correct_answer)}</p><p class="muted"><strong>Explanation:</strong> ${esc(question.explanation)}</p><p class="muted"><strong>Marks:</strong> ${question.marks_awarded} / ${question.marks_possible}</p></div>`).join('')}</div>`).join('')
                : `<div class="review"><h2>Analysis unavailable</h2><p class="muted">No detailed section analysis was returned for this submission.</p></div>`;
            document.getElementById('main-wrapper').style.display = 'none';
            document.getElementById('sidebar').style.display = 'none';
            window.scrollTo(0, 0);
        }

        function updateMicStatus(value) {
            micStatusCopy.textContent = value;
        }

        async function initMedia() {
            faceStatus.innerText = 'Requesting camera and microphone access...';
            scanStage.classList.remove('success', 'error');
            try {
                streamRef = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
                video.srcObject = streamRef;
                await video.play().catch(() => {});
                faceStatus.innerText = 'Camera and microphone enabled. Please verify your face to enter.';
                updateMicStatus('Microphone live and ready for environment checks.');
                updateMediaChecklist();
            } catch (error) {
                faceStatus.innerText = 'Camera and microphone access are required to start this exam.';
                updateMicStatus('Microphone access denied or unavailable.');
                setChecklistStatus('check-camera', 'error', 'Blocked');
                setChecklistStatus('check-mic', 'error', 'Blocked');
                showToast('Permissions required', 'Camera and microphone access are required to start this exam.', 'danger');
            }
        }

        async function waitForCameraFrame(timeoutMs = 2500) {
            const start = Date.now();
            while (Date.now() - start < timeoutMs) {
                const image = getEvidenceFrame();
                if (image) return image;
                await new Promise(resolve => setTimeout(resolve, 150));
            }
            return '';
        }

        async function verifyFaceAndStart() {
            if (verifyFaceBtn.disabled) return;
            verifyFaceBtn.disabled = true;
            enableMediaBtn.disabled = true;
            fullscreenBtn.disabled = true;
            verifyFaceBtn.innerText = 'Verifying...';
            scanStage.classList.remove('success', 'error');
            scanStage.classList.add('scanning');
            faceStatus.innerText = 'Preparing live camera frame for verification...';
            try {
                if (!streamRef) {
                    await initMedia();
                    if (!streamRef) return;
                }
                if (!document.fullscreenElement) {
                    await enableFullscreen();
                }
                const image = await waitForCameraFrame();
                if (!image) {
                    faceStatus.innerText = 'Camera preview is not ready yet. Please wait a moment and try again.';
                    scanStage.classList.remove('scanning');
                    scanStage.classList.add('error');
                    showToast('Camera warming up', 'Waiting for camera frame. Please try again.', 'warn');
                    return;
                }
                faceStatus.innerText = 'Verifying your face. Please look at the camera...';
                const res = await fetch('/verify_face', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ image })
                });
                const raw = await res.text();
                let data = {};
                try {
                    data = raw ? JSON.parse(raw) : {};
                } catch (parseError) {
                    throw new Error('The server returned an invalid verification response.');
                }
                if (!res.ok || data.status !== 'success') {
                    const message = data.message || 'Face verification failed.';
                    faceStatus.innerText = message;
                    scanStage.classList.remove('scanning');
                    scanStage.classList.add('error');
                    showToast('Verification failed', message, 'danger');
                    return;
                }
                faceVerified = !!data.passed;
                faceMatchScore = data.score || 0;
                faceStatus.innerText = faceVerified ? `Face verified. Match score ${faceMatchScore}.` : `Verification failed. Match score ${faceMatchScore}, threshold ${data.threshold}.`;
                updateMediaChecklist();
                scanStage.classList.remove('scanning');
                scanStage.classList.add(faceVerified ? 'success' : 'error');
                if (!faceVerified) {
                    showToast('Face not matched', `Match score ${faceMatchScore}, threshold ${data.threshold}.`, 'warn');
                    return;
                }
                if (!readinessSatisfied()) {
                    showToast('Final check pending', 'Fullscreen and online status must still be active before the exam can open.', 'warn');
                    return;
                }
                startExamExperience();
            } catch (err) {
                const message = err?.message || 'Unable to verify face right now. Please try again.';
                faceStatus.innerText = message;
                scanStage.classList.remove('scanning');
                scanStage.classList.add('error');
                showToast('Verification error', message, 'danger');
            } finally {
                verifyFaceBtn.disabled = false;
                enableMediaBtn.disabled = false;
                fullscreenBtn.disabled = false;
                verifyFaceBtn.innerText = 'Verify Face And Start';
            }
        }

        function getEvidenceFrame() {
            if (video.videoWidth) {
                const canvas = document.createElement('canvas');
                const sourceWidth = Math.max(1, video.videoWidth || 320);
                const sourceHeight = Math.max(1, video.videoHeight || 240);
                // Retain enough detail for the server-side model to see handheld objects.
                const targetWidth = Math.min(640, sourceWidth);
                const targetHeight = Math.max(1, Math.round(sourceHeight * (targetWidth / sourceWidth)));
                canvas.width = targetWidth;
                canvas.height = targetHeight;
                canvas.getContext('2d').drawImage(video, 0, 0, targetWidth, targetHeight);
                latestEvidenceFrame = canvas.toDataURL('image/jpeg', 0.82);
            }
            return latestEvidenceFrame;
        }

        function emitTabSwitch(reason) {
            if (!timerStarted || examSubmitted) return;
            const now = Date.now();
            if (now - lastTabSwitchEmitAt < 2000) return;
            lastTabSwitchEmitAt = now;
            socket.emit('tab_switch', {
                student_info: studentInfo,
                msg: reason,
                evidence_image: getEvidenceFrame()
            });
        }

        function setupAudio(stream) {
            audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            const source = audioCtx.createMediaStreamSource(stream);
            const analyser = audioCtx.createAnalyser();
            analyser.fftSize = 256;
            source.connect(analyser);
            const dataArray = new Uint8Array(analyser.frequencyBinCount);
            (function loop() {
                analyser.getByteFrequencyData(dataArray);
                const avg = dataArray.reduce((a, b) => a + b, 0) / dataArray.length;
                audioBar.style.width = `${Math.min(100, avg * 3.5)}%`;
                updateMicStatus(avg > 35 ? 'Environment noise is rising. Keep the room quiet.' : 'Microphone is active and within normal range.');
                if (avg > 35 && !examSubmitted && Date.now() - lastAudioEmitAt > 4000) {
                    lastAudioEmitAt = Date.now();
                    socket.emit('audio_violation', { student_info: studentInfo, evidence_image: getEvidenceFrame() });
                }
                requestAnimationFrame(loop);
            })();
        }

        function startAI() {
            if (aiInterval) return;
            aiInterval = setInterval(() => {
                if (!video.videoWidth || examSubmitted) return;
                const image = getEvidenceFrame();
                if (!image) return;
                socket.emit('video_frame', { image, student_info: studentInfo });
            }, 1500);
        }

        function startLiveStatus() {
            if (liveStatusInterval) return;
            liveStatusInterval = setInterval(() => {
                if (examSubmitted) return;
                socket.emit('exam_status', {
                    student_id: studentId,
                    student_name: studentName,
                    year_group: yearGroup,
                    remaining_seconds: timeLeft,
                    mic_status: (parseFloat(audioBar.style.width) || 0) > 65 ? 'active' : 'normal',
                    face_verified: faceVerified,
                    face_match_score: faceMatchScore,
                    violation_count: localViolationCount,
                    violation_score_total: localViolationScore
                });
            }, 3000);
        }

        function startPersistLoop() {
            if (persistInterval) return;
            persistInterval = setInterval(persistExamState, 5000);
        }

        function startTimer() {
            if (timerStarted) return;
            timerStarted = true;
            updateTimerRing();
            timerInterval = setInterval(() => {
                const m = Math.floor(timeLeft / 60);
                const s = timeLeft % 60;
                timerDisplay.innerText = `${m}:${s < 10 ? '0' : ''}${s}`;
                updateTimerRing();
                if (timeLeft <= 0) {
                    clearInterval(timerInterval);
                    finalProcess();
                    return;
                }
                timeLeft -= 1;
            }, 1000);
        }

        function startExamExperience() {
            resetAttemptUI();
            document.getElementById('permission-shield').style.display = 'none';
            document.getElementById('sidebar').style.display = 'flex';
            document.getElementById('main-wrapper').style.display = 'flex';
            setupAudio(streamRef);
            renderExam();
            if (isResuming) {
                const saved = safeParseStorage();
                if (saved) restoreFromSavedState(saved);
                isResuming = false;
            } else if (resumeState.active && resumeState.remaining_seconds > 0) {
                timeLeft = Number(resumeState.remaining_seconds || totalDurationSeconds);
                updateViolationScore(Number(resumeState.violation_score_total || 0), 20);
                updateTrustMeter(Number(resumeState.risk_score || 0), resumeState.risk_level || 'Low');
            }
            startAI();
            startLiveStatus();
            startPersistLoop();
            startTimer();
            updateMediaChecklist();
            examStateCopy.textContent = 'Exam live. All monitoring, answer saving, and reconnect support are active.';
            showToast('Exam started', 'Mission control is live. Your answers will now save locally for reconnect recovery.', 'info');
        }

        window.addEventListener('blur', () => emitTabSwitch('Tab Switch / Window Minimized'));
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) emitTabSwitch('Tab Switch / Page Hidden');
        });
        window.addEventListener('pagehide', () => emitTabSwitch('Tab Switch / Page Hidden'));

        ['mousemove', 'keydown', 'click', 'touchstart', 'scroll'].forEach(evt => document.addEventListener(evt, markActivity, { passive: true }));
        ['copy', 'paste', 'contextmenu'].forEach(evt => document.addEventListener(evt, e => {
            e.preventDefault();
            e.stopPropagation();
            const reason = evt === 'contextmenu' ? 'Right Click' : evt.charAt(0).toUpperCase() + evt.slice(1);
            addLog(`Restricted action: ${reason}`);
            flashAlert(`Restricted action: ${reason}`);
            emitTabSwitch(`Restricted Action: ${reason}`);
        }));
        document.onkeydown = e => {
            if (e.ctrlKey && [67, 86, 85, 73, 83].includes(e.keyCode)) {
                e.preventDefault();
                e.stopPropagation();
                addLog('Restricted key combination');
                flashAlert('Restricted key combination');
                emitTabSwitch('Restricted Keys');
                return false;
            }
        };

        setInterval(() => {
            if (!timerStarted || examSubmitted || afkReported) return;
            if (Date.now() - lastActivityAt > 120000) {
                afkReported = true;
                socket.emit('tab_switch', { student_info: studentInfo, msg: 'Inactivity (AFK) > 2 Minutes', evidence_image: getEvidenceFrame() });
            }
        }, 15000);

        socket.on('cheat_alert', data => (data.alerts || []).forEach(alert => {
            const message = typeof alert === 'string' ? alert : alert.message;
            const score = typeof alert === 'string' ? localViolationScore : Number(alert.total_score || localViolationScore);
            const threshold = typeof alert === 'string' ? 20 : Number(alert.threshold || 20);
            localViolationCount += 1;
            addLog(`${message}${typeof alert === 'object' ? ` (+${alert.score})` : ''}`);
            updateViolationScore(score, threshold);
            if (typeof alert === 'object') {
                updateTrustMeter(Number(alert.risk_score || 0), alert.risk_level || 'Low');
            }
            const lower = String(message).toLowerCase();
            if (lower.includes('phone') || lower.includes('no face') || lower.includes('restricted') || lower.includes('loud noise') || lower.includes('multiple people') || lower.includes('tab switch') || lower.includes('afk')) flashAlert(message);
            if (Number(localViolationScore) > Number(threshold)) {
                triggerAutoSubmit(threshold);
            }
            persistExamState();
        }));

        socket.on('admin_announcement', payload => {
            if (!payload || !payload.message) return;
            if (payload.created_at && payload.created_at === lastAnnouncementAt) return;
            lastAnnouncementAt = payload.created_at || '';
            addLog(`Admin notice: ${payload.message}`);
            showToast(payload.student_id ? 'Admin Warning' : 'Admin Announcement', payload.message, payload.student_id ? 'danger' : 'info');
        });

        function initFromResumeState() {
            questionState = defaultQuestionState();
            renderSectionNav();
            updateNetworkStatus();
            updateFullscreenStatus();
            updateMediaChecklist();
            timeLeft = resumeState.active && resumeState.remaining_seconds > 0 ? Number(resumeState.remaining_seconds) : totalDurationSeconds;
            localViolationCount = Number(resumeState.violation_count || 0);
            localViolationScore = Number(resumeState.violation_score_total || 0);
            updateViolationScore(localViolationScore, 20);
            updateTrustMeter(Number(resumeState.risk_score || 0), resumeState.risk_level || 'Low');
            updateTimerRing();
            initSavedAttemptHint();
            if (resumeState.active && resumeState.remaining_seconds > 0) {
                showToast('Active attempt detected', 'The server still sees an active exam session. Use resume support if your page was refreshed.', 'info');
            }
        }

        window.addEventListener('online', updateNetworkStatus);
        window.addEventListener('offline', updateNetworkStatus);
        ['fullscreenchange', 'webkitfullscreenchange', 'mozfullscreenchange', 'MSFullscreenChange'].forEach(evt => document.addEventListener(evt, updateFullscreenStatus));
        window.addEventListener('beforeunload', () => {
            if (!examSubmitted) persistExamState();
        });
        window.addEventListener('pageshow', () => {
            updateNetworkStatus();
            updateFullscreenStatus();
        });

        initFromResumeState();
    </script>
    <script>
        (function () {
            const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            const enterPage = () => {
                document.body.classList.add('page-ready');
                document.body.classList.remove('page-exit');
            };
            window.transitionTo = function (url) {
                if (!url) return;
                if (reduceMotion) { window.location.href = url; return; }
                document.body.classList.remove('page-ready');
                document.body.classList.add('page-exit');
                setTimeout(() => { window.location.href = url; }, 220);
            };
            document.addEventListener('click', (event) => {
                const link = event.target.closest('a[href]');
                if (!link) return;
                const href = link.getAttribute('href') || '';
                if (!href || href.startsWith('#') || link.target === '_blank' || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
                const absoluteUrl = new URL(link.href, window.location.href);
                if (absoluteUrl.origin !== window.location.origin) return;
                if (typeof window.transitionTo !== 'function') return;
                event.preventDefault();
                transitionTo(absoluteUrl.href);
            });
            window.addEventListener('pageshow', enterPage);
            if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', enterPage);
            else enterPage();
        })();
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ProctorX | Reset Password</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-auth.css', v='5') }}">
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body class="auth-page">
    <span class="orb orb-one"></span><span class="orb orb-two"></span><span class="orb orb-three"></span>
    <main class="auth-layout">
        <section class="auth-aside">
            <a href="/login" class="brand" aria-label="ProctorX home"><img class="brand-logo" src="{{ url_for('static', filename='proctorx-logo.png', v='3') }}" alt=""><span>Proctor<em>X</em></span></a>
            <div class="aside-copy"><div class="aside-kicker">Account recovery</div><h1>Get back to your assessment.</h1><p>Use a recovery method you selected when creating your student account, then choose a new secure password.</p></div>
            <div class="assurance"><span class="assurance-dot"></span>Identity checks protect your account</div>
        </section>
        <section class="auth-content">
            <div class="auth-card">
                <div class="form-eyebrow">Password reset</div>
                {% if mode == 'otp' %}
                    <h2>Enter your email code</h2><p class="form-intro">We sent a six-digit code to {{ email }}. It expires in 10 minutes.</p>
                {% elif mode == 'email' %}
                    <h2>Reset with email OTP</h2><p class="form-intro">Confirm your registered email and we will send a six-digit verification code.</p>
                {% elif mode == 'phone_otp' %}
                    <h2>Verify your phone number</h2><p class="form-intro">We will send an SMS code to your registered phone number ending in {{ phone[-4:] if phone|length > 4 else phone }}.</p>
                {% elif mode == 'phone' %}
                    <h2>Reset with phone OTP</h2><p class="form-intro">Enter your roll number and registered phone number to receive a verification SMS.</p>
                {% else %}
                    <h2>Reset your password</h2><p class="form-intro">Choose a recovery method you enabled during registration.</p>
                {% endif %}
                {% if error %}<div class="notice error">{{ error }}</div>{% endif %}

                {# --- EMAIL OTP: enter code --- #}
                {% if mode == 'otp' %}
                    <form action="/forgot_password" method="POST"><input type="hidden" name="action" value="confirm_email_otp"><div class="field"><label for="otp">Email verification code</label><input id="otp" type="text" inputmode="numeric" name="otp" maxlength="6" pattern="[0-9]{6}" placeholder="6-digit code" required></div><div class="field"><label for="password">New password</label><input id="password" type="password" name="new_password" placeholder="At least 8 characters" oninput="checkStrength(this.value)" required></div><div class="meter-container"><div id="strength-bar"></div></div><button class="primary-button proctorx-wobbly proctorx-btn-loading" type="submit">Verify code and update password</button></form>
                    <div class="form-footer"><a href="/forgot_password?method=email">Use a different recovery method</a></div>

                {# --- EMAIL OTP: request code --- #}
                {% elif mode == 'email' or request.args.get('method') == 'email' %}
                    <form action="/forgot_password" method="POST"><input type="hidden" name="action" value="request_email_otp"><div class="field"><label for="userid">Roll number</label><input id="userid" type="text" name="userid" maxlength="10" placeholder="Enter your roll number" required></div><div class="field"><label for="email">Registered email address</label><input id="email" type="email" name="email" placeholder="you@example.com" autocomplete="email" required></div><button class="primary-button proctorx-wobbly proctorx-btn-loading" type="submit">Send email OTP</button></form>
                    <div class="form-footer"><a href="/forgot_password">Use phone verification instead</a></div>

                {# --- PHONE OTP: Firebase SMS verification --- #}
                {% elif mode == 'phone_otp' %}
                    <div id="phone-otp-container">
                        <div id="otp-step-send">
                            <p style="margin-bottom:1rem;color:var(--text-secondary,#a0aec0);">Click the button below to receive an SMS verification code.</p>
                            <div id="recaptcha-container"></div>
                            <button id="send-otp-btn" class="primary-button" type="button" style="margin-top:1rem;">Send SMS Code</button>
                        </div>
                        <div id="otp-step-verify" style="display:none;">
                            <form id="verify-otp-form" action="/forgot_password" method="POST">
                                <input type="hidden" name="action" value="confirm_phone_otp">
                                <input type="hidden" name="firebase_id_token" id="firebase_id_token">
                                <div class="field">
                                    <label for="sms-code">SMS verification code</label>
                                    <input id="sms-code" type="text" inputmode="numeric" maxlength="6" pattern="[0-9]{6}" placeholder="6-digit code" required>
                                </div>
                                <div class="field">
                                    <label for="password">New password</label>
                                    <input id="password" type="password" name="new_password" placeholder="At least 8 characters" oninput="checkStrength(this.value)" required>
                                </div>
                                <div class="meter-container"><div id="strength-bar"></div></div>
                                <button id="verify-otp-btn" class="primary-button" type="button">Verify code and update password</button>
                            </form>
                        </div>
                        <div id="otp-status" style="margin-top:1rem;color:var(--text-secondary,#a0aec0);"></div>
                    </div>
                    <div class="form-footer"><a href="/forgot_password">Use a different recovery method</a></div>

                {# --- PHONE OTP: enter roll + phone --- #}
                {% elif mode == 'phone' or request.args.get('method') == 'phone' %}
                    <form action="/forgot_password" method="POST">
                        <input type="hidden" name="action" value="request_phone_otp">
                        <div class="field"><label for="userid">Roll number</label><input id="userid" type="text" name="userid" maxlength="10" placeholder="Enter your roll number" required></div>
                        <div class="field"><label for="phone">Registered phone number</label><input id="phone" type="tel" name="phone" placeholder="+91XXXXXXXXXX" required></div>
                        <button class="primary-button proctorx-wobbly proctorx-btn-loading" type="submit">Send phone OTP</button>
                    </form>
                    <div class="form-footer"><a href="/forgot_password?method=email">Use email verification instead</a></div>

                {# --- DEFAULT: choose recovery method --- #}
                {% else %}
                    <div class="branch-section recovery-section"><p>Select recovery method</p><div class="branch-grid"><a class="photo-btn" href="/forgot_password?method=phone">Phone OTP</a><a class="photo-btn" href="/forgot_password?method=email">Email OTP</a></div></div>
                {% endif %}
                <div class="form-footer"><a href="/login">Return to sign in</a></div>
            </div>
        </section>
    </main>

    {# --- Firebase Phone Auth JS (only loaded on phone_otp mode) --- #}
    {% if mode == 'phone_otp' and firebase_config %}
    <script type="module">
        import { initializeApp } from "https://www.gstatic.com/firebasejs/11.8.1/firebase-app.js";
        import { getAuth, RecaptchaVerifier, signInWithPhoneNumber } from "https://www.gstatic.com/firebasejs/11.8.1/firebase-auth.js";

        const firebaseConfig = {{ firebase_config | tojson }};
        const fbApp = initializeApp(firebaseConfig);
        const auth = getAuth(fbApp);

        // The phone number to verify (passed from server, must include country code)
        const phoneNumber = {{ phone | tojson }};

        const statusEl = document.getElementById('otp-status');
        const sendBtn = document.getElementById('send-otp-btn');
        const stepSend = document.getElementById('otp-step-send');
        const stepVerify = document.getElementById('otp-step-verify');
        const verifyBtn = document.getElementById('verify-otp-btn');

        let confirmationResult = null;

        // Setup invisible reCAPTCHA
        const recaptchaVerifier = new RecaptchaVerifier(auth, 'recaptcha-container', {
            size: 'invisible',
            callback: () => {},
            'expired-callback': () => {
                statusEl.textContent = 'reCAPTCHA expired. Please try again.';
                statusEl.style.color = '#ff839d';
            }
        });

        sendBtn.addEventListener('click', async () => {
            sendBtn.disabled = true;
            statusEl.textContent = 'Sending SMS...';
            statusEl.style.color = 'var(--text-secondary, #a0aec0)';

            // Ensure phone has country code
            let formattedPhone = phoneNumber.trim();
            if (!formattedPhone.startsWith('+')) {
                // Default to India (+91) if no country code
                formattedPhone = formattedPhone.replace(/^0+/, '');
                formattedPhone = '+91' + formattedPhone;
            }

            try {
                confirmationResult = await signInWithPhoneNumber(auth, formattedPhone, recaptchaVerifier);
                statusEl.textContent = 'SMS sent! Enter the code below.';
                statusEl.style.color = '#72f4c8';
                stepSend.style.display = 'none';
                stepVerify.style.display = 'block';
            } catch (error) {
                console.error('SMS send error:', error);
                sendBtn.disabled = false;
                if (error.code === 'auth/too-many-requests') {
                    statusEl.textContent = 'Too many attempts. Please wait a few minutes and try again.';
                } else if (error.code === 'auth/invalid-phone-number') {
                    statusEl.textContent = 'Invalid phone number format. Use format like +91XXXXXXXXXX.';
                } else if (error.code === 'auth/captcha-check-failed') {
                    statusEl.textContent = 'reCAPTCHA verification failed. Please refresh and try again.';
                } else {
                    statusEl.textContent = 'Failed to send SMS: ' + (error.message || 'Unknown error');
                }
                statusEl.style.color = '#ff839d';
            }
        });

        verifyBtn.addEventListener('click', async () => {
            const code = document.getElementById('sms-code').value.trim();
            const password = document.getElementById('password').value;

            if (!code || code.length !== 6) {
                statusEl.textContent = 'Please enter the 6-digit code.';
                statusEl.style.color = '#ff839d';
                return;
            }
            if (password.length < 8) {
                statusEl.textContent = 'Password must be at least 8 characters.';
                statusEl.style.color = '#ff839d';
                return;
            }

            verifyBtn.disabled = true;
            statusEl.textContent = 'Verifying code...';
            statusEl.style.color = 'var(--text-secondary, #a0aec0)';

            try {
                const result = await confirmationResult.confirm(code);
                // Get the Firebase ID token to send to our backend
                const idToken = await result.user.getIdToken();
                document.getElementById('firebase_id_token').value = idToken;

                statusEl.textContent = 'Phone verified! Updating password...';
                statusEl.style.color = '#72f4c8';

                // Submit the form to the backend
                document.getElementById('verify-otp-form').submit();
            } catch (error) {
                console.error('Verification error:', error);
                verifyBtn.disabled = false;
                if (error.code === 'auth/invalid-verification-code') {
                    statusEl.textContent = 'Invalid code. Please check and try again.';
                } else if (error.code === 'auth/code-expired') {
                    statusEl.textContent = 'Code expired. Please request a new one.';
                } else {
                    statusEl.textContent = 'Verification failed: ' + (error.message || 'Unknown error');
                }
                statusEl.style.color = '#ff839d';
            }
        });
    </script>
    {% endif %}

    <script>
        const rollNumber = document.getElementById('userid');
        if (rollNumber) rollNumber.addEventListener('input', function () { this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, ''); });
        const otp = document.getElementById('otp');
        if (otp) otp.addEventListener('input', function () { this.value = this.value.replace(/\D/g, ''); });
        const smsCode = document.getElementById('sms-code');
        if (smsCode) smsCode.addEventListener('input', function () { this.value = this.value.replace(/\D/g, ''); });
        function checkStrength(password) { let score = 0; if (password.length >= 8) score += 25; if (/[A-Z]/.test(password)) score += 25; if (/[0-9]/.test(password)) score += 25; if (/[^A-Za-z0-9]/.test(password)) score += 25; const bar = document.getElementById('strength-bar'); if (!bar) return; bar.style.width = `${score}%`; bar.style.background = score < 50 ? '#ff839d' : score < 100 ? '#ffd36c' : '#72f4c8'; }
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ProctorX | Complete Google Profile</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-auth.css', v='4') }}">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-dialog.css') }}">
    <script src="{{ url_for('static', filename='proctorx-dialog.js') }}" defer></script>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body class="auth-page">
    <span class="orb orb-one"></span><span class="orb orb-two"></span><span class="orb orb-three"></span>
    <main class="auth-layout registration-layout">
        <section class="auth-aside">
            <div class="scan-lines" aria-hidden="true"></div>
            <a href="/login" class="brand" aria-label="ProctorX home"><img class="brand-logo" src="{{ url_for('static', filename='proctorx-logo.png', v='3') }}" alt=""><span>Proctor<em>X</em></span></a>
            <div class="aside-copy">
                <div class="aside-kicker">Google account verified</div>
                <h1>Finish your student profile.</h1>
                <p>Your Google email is protected and cannot be changed here. Complete the assessment details below to activate your ProctorX account.</p>
            </div>
            <div class="assurance"><span class="assurance-dot"></span><span class="status-wave" aria-hidden="true"><i></i><i></i><i></i></span>Verified Google identity linked securely</div>
        </section>
        <section class="auth-content">
            <div class="auth-card">
                <div class="form-eyebrow">One last step</div>
                <h2>Complete your account</h2>
                <p class="form-intro">Your name and roll number remain editable. The verified Google email is locked to prevent account misuse.</p>
                <form id="google-profile-form" enctype="multipart/form-data">
                    <div class="field"><label for="google-email">Verified Google email</label><input id="google-email" type="email" value="{{ google_profile.email }}" readonly aria-readonly="true"></div>
                    <div class="form-grid">
                        <div class="field"><label for="name">Full name</label><input id="name" type="text" name="name" value="{{ google_profile.name }}" required></div>
                        <div class="field"><label for="userid">Roll number</label><input id="userid" type="text" name="userid" maxlength="10" placeholder="10 characters" required></div>
                    </div>
                    <div class="branch-section">
                        <p>Select your branch</p>
                        <div class="branch-grid">
                            <label><input type="checkbox" class="branch-cb" name="branch" value="CSE"> CSE</label><label><input type="checkbox" class="branch-cb" name="branch" value="CSE-AI&ML"> CSE (AI & ML)</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="CSE-DS"> CSE (DS)</label><label><input type="checkbox" class="branch-cb" name="branch" value="IT"> IT</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="ECE"> ECE</label><label><input type="checkbox" class="branch-cb" name="branch" value="EEE"> EEE</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="CIVIL"> Civil</label><label><input type="checkbox" class="branch-cb" name="branch" value="MECH"> Mechanical</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="MCT"> MCT</label><label><input type="checkbox" class="branch-cb" name="branch" value="MET"> MET</label>
                        </div>
                    </div>
                    <div class="form-grid">
                        <div class="field"><label for="semester">Current semester</label><select id="semester" name="semester" required><option value="" selected disabled>Select semester</option><option value="1-1">1st year, semester 1</option><option value="1-2">1st year, semester 2</option><option value="2-1">2nd year, semester 1</option><option value="2-2">2nd year, semester 2</option><option value="3-1">3rd year, semester 1</option><option value="3-2">3rd year, semester 2</option><option value="4-1">4th year, semester 1</option><option value="4-2">4th year, semester 2</option></select></div>
                        <div class="field"><label for="phone">Phone number</label><input id="phone" type="text" name="phone" placeholder="Registered phone number" required></div>
                    </div>
                    <div class="photo-section">
                        <p>Profile photo required for face verification</p>
                        <div class="photo-actions"><input type="file" id="profile-pic-input" name="profile_pic" accept="image/png,image/jpeg" hidden><button type="button" class="photo-btn" onclick="profilePicInput.click()">Upload photo</button><button type="button" class="photo-btn" onclick="openCameraModal()">Use camera</button></div>
                        <div id="photo-file-name" class="photo-name">Upload a clear, front-facing image.</div><img id="photo-preview" class="photo-preview" alt="Selected profile preview">
                    </div>
                    <button class="primary-button proctorx-wobbly proctorx-btn-loading" type="submit">Activate ProctorX account</button>
                </form>
                <div class="form-footer"><a href="/login">Use a different sign-in method</a></div>
            </div>
        </section>
    </main>
    <div id="camera-modal"><div class="camera-card"><h3>Capture profile photo</h3><p>Keep your face centered in a bright, clear frame.</p><video id="camera-stream" autoplay playsinline muted></video><canvas id="camera-canvas" hidden></canvas><div class="camera-actions"><button type="button" class="photo-btn" onclick="capturePhoto()">Capture photo</button><button type="button" class="photo-btn" onclick="closeCameraModal()">Cancel</button></div></div></div>
    <script>
        let cameraStream = null;
        const profilePicInput = document.getElementById('profile-pic-input'); const photoPreview = document.getElementById('photo-preview'); const photoFileName = document.getElementById('photo-file-name'); const cameraModal = document.getElementById('camera-modal'); const cameraVideo = document.getElementById('camera-stream'); const cameraCanvas = document.getElementById('camera-canvas');
        document.querySelectorAll('.branch-cb').forEach((checkbox) => checkbox.addEventListener('change', () => { if (checkbox.checked) document.querySelectorAll('.branch-cb').forEach((other) => { if (other !== checkbox) other.checked = false; }); }));
        document.getElementById('userid').addEventListener('input', function () { this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, ''); });
        function updatePhotoPreview(file, label) { if (!file) return; photoFileName.textContent = label || file.name; const reader = new FileReader(); reader.onload = () => { photoPreview.src = reader.result; photoPreview.style.display = 'block'; }; reader.readAsDataURL(file); }
        profilePicInput.addEventListener('change', () => updatePhotoPreview(profilePicInput.files[0]));
        async function openCameraModal() { try { cameraStream = await navigator.mediaDevices.getUserMedia({ video: true }); cameraVideo.srcObject = cameraStream; cameraModal.style.display = 'flex'; } catch { await proctorxAlert('Camera access was denied or is unavailable on this device.', { type: 'warning', title: 'Camera access unavailable' }); } }
        function closeCameraModal() { if (cameraStream) cameraStream.getTracks().forEach((track) => track.stop()); cameraStream = null; cameraVideo.srcObject = null; cameraModal.style.display = 'none'; }
        function capturePhoto() { if (!cameraVideo.videoWidth) return; cameraCanvas.width = cameraVideo.videoWidth; cameraCanvas.height = cameraVideo.videoHeight; cameraCanvas.getContext('2d').drawImage(cameraVideo, 0, 0); cameraCanvas.toBlob((blob) => { if (!blob) return; const file = new File([blob], 'profile-photo.jpg', { type: 'image/jpeg' }); const transfer = new DataTransfer(); transfer.items.add(file); profilePicInput.files = transfer.files; updatePhotoPreview(file, 'Photo captured from camera'); closeCameraModal(); }, 'image/jpeg', .92); }
        document.getElementById('google-profile-form').addEventListener('submit', async (event) => { event.preventDefault(); const formData = new FormData(event.currentTarget); if (!formData.get('branch')) return proctorxAlert('Select one branch before activating your account.', { type: 'warning', title: 'Branch required' }); if (!profilePicInput.files.length) return proctorxAlert('Upload or capture a profile photo for face verification.', { type: 'warning', title: 'Profile photo required' }); const response = await fetch('/auth/google/complete-profile', { method: 'POST', body: formData }); const data = await response.json(); if (data.status !== 'success') return proctorxAlert(data.message || 'Your profile could not be created.', { type: 'danger', title: 'Profile setup failed' }); await proctorxAlert('Your verified Google account is now linked to ProctorX.', { type: 'success', title: 'Account activated' }); window.location.href = data.redirect_url; });
        window.addEventListener('beforeunload', closeCameraModal);
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ProctorX | Sign In</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-auth.css', v='3') }}">
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body class="auth-page">
    <div class="particle-field" aria-hidden="true"></div><div class="cursor-glow" aria-hidden="true"></div>
    <span class="orb orb-one"></span><span class="orb orb-two"></span><span class="orb orb-three"></span>
    <main class="auth-layout">
        <section class="auth-aside">
            <div class="scan-lines" aria-hidden="true"></div>
            <a href="/login" class="brand" aria-label="ProctorX home"><img class="brand-logo" src="{{ url_for('static', filename='proctorx-logo.png', v='3') }}" alt=""><span>Proctor<em>X</em></span></a>
            <div class="aside-copy">
                <div class="aside-kicker">Smart assessment platform</div>
                <h1>Confidence in every attempt.</h1>
                <p>Secure assessments built around real-time monitoring, focused workflows, and clear performance insights.</p>
            </div>
            <div class="assurance"><span class="assurance-dot"></span><span class="status-wave" aria-hidden="true"><i></i><i></i><i></i></span>Protected session and live integrity checks</div>
        </section>
        <section class="auth-content">
            <div class="auth-card">
                <div class="form-eyebrow">Welcome back</div>
                <h2 id="form-title">Sign in to ProctorX</h2>
                <p class="form-intro" id="form-intro">Continue your assessment journey with your student account.</p>
                <div class="role-switch" role="tablist" aria-label="Account type">
                    <button class="active" id="student-tab" type="button" onclick="switchRole('student')">Student</button>
                    <button id="admin-tab" type="button" onclick="switchRole('admin')">Administrator</button>
                </div>
                {% if error %}<div class="notice error">{{ error }}</div>{% endif %}
                {% if success %}<div class="notice success">{{ success }}</div>{% endif %}
                <form id="student-form" action="/login" method="POST">
                    <div class="field"><label for="student-id">Roll number</label><input id="student-id" type="text" name="user_id" placeholder="Enter your roll number" autocomplete="username" required></div>
                    <div class="field"><label for="student-password">Password</label><div class="password-field"><input id="student-password" type="password" name="password" placeholder="Enter your password" autocomplete="current-password" required><button class="password-toggle" type="button" aria-label="Show password" onclick="togglePassword('student-password', this)">◉</button></div></div>
                    <button class="primary-button proctorx-wobbly proctorx-btn-loading" type="submit">Enter student portal</button>
                    <div class="form-row"><span>Need help accessing your account?</span><a href="/forgot_password">Reset password</a></div>
                    <div class="auth-divider">or continue with</div>
                    <a class="google-signin" href="/auth/google"><span class="google-mark">G</span>Sign in with Google</a>
                </form>
                <form id="admin-form" action="/login" method="POST" class="hidden">
                    <div class="field"><label for="admin-id">Administrator ID</label><input id="admin-id" type="text" name="user_id" placeholder="Enter administrator ID" autocomplete="username" required></div>
                    <div class="field"><label for="admin-password">Password</label><div class="password-field"><input id="admin-password" type="password" name="password" placeholder="Enter your password" autocomplete="current-password" required><button class="password-toggle" type="button" aria-label="Show password" onclick="togglePassword('admin-password', this)">◉</button></div></div>
                    <button class="primary-button proctorx-wobbly proctorx-btn-loading" type="submit">Open command center</button>
                    <div class="form-row"><span>Admin access is restricted.</span></div>
                </form>
                <div class="form-footer">New to ProctorX? <a href="/register">Create your student account</a></div>
            </div>
        </section>
    </main>
    <script>
        function switchRole(role) {
            const student = role === 'student';
            document.getElementById('student-form').classList.toggle('hidden', !student);
            document.getElementById('admin-form').classList.toggle('hidden', student);
            document.getElementById('student-tab').classList.toggle('active', student);
            document.getElementById('admin-tab').classList.toggle('active', !student);
            document.getElementById('form-title').textContent = student ? 'Sign in to ProctorX' : 'Administrator access';
            document.getElementById('form-intro').textContent = student ? 'Continue your assessment journey with your student account.' : 'Review live sessions, insights, and assessment settings.';
        }
        function togglePassword(inputId, button) {
            const input = document.getElementById(inputId);
            const visible = input.type === 'text';
            input.type = visible ? 'password' : 'text';
            button.textContent = visible ? '◉' : '◌';
            button.setAttribute('aria-label', visible ? 'Show password' : 'Hide password');
        }
        document.querySelectorAll('.field input').forEach((input) => input.addEventListener('input', () => {
            const field = input.closest('.field');
            if (!input.value) { field.classList.remove('valid', 'invalid'); return; }
            field.classList.toggle('valid', input.checkValidity());
            field.classList.toggle('invalid', !input.checkValidity());
        }));
        document.querySelectorAll('form').forEach((form) => form.addEventListener('submit', (event) => {
            if (!form.checkValidity()) return;
            form.querySelector('.primary-button').classList.add('loading');
        }));
        const particleField = document.querySelector('.particle-field');
        for (let index = 0; index < 34; index += 1) {
            const particle = document.createElement('span');
            particle.className = 'particle';
            particle.style.left = `${(index * 37) % 100}%`;
            particle.style.top = `${(index * 61) % 100}%`;
            particle.style.setProperty('--duration', `${5 + (index % 7)}s`);
            particle.style.setProperty('--delay', `${-(index % 6)}s`);
            particle.style.setProperty('--travel-x', `${(index % 2 ? 1 : -1) * (16 + index)}px`);
            particle.style.setProperty('--travel-y', `${-18 - (index % 5) * 12}px`);
            particleField.appendChild(particle);
        }
        const layout = document.querySelector('.auth-layout');
        document.addEventListener('pointermove', (event) => {
            document.documentElement.style.setProperty('--cursor-x', `${event.clientX}px`);
            document.documentElement.style.setProperty('--cursor-y', `${event.clientY}px`);
            if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
            const rect = layout.getBoundingClientRect();
            const tiltX = (event.clientY - rect.top - rect.height / 2) / -55;
            const tiltY = (event.clientX - rect.left - rect.width / 2) / 55;
            layout.style.transform = `perspective(1400px) rotateX(${Math.max(-3, Math.min(3, tiltX))}deg) rotateY(${Math.max(-3, Math.min(3, tiltY))}deg)`;
        });
        document.addEventListener('pointerleave', () => { layout.style.transform = ''; });
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ProctorX | Create Account</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-auth.css', v='3') }}">
    <link rel="stylesheet" href="{{ url_for('static', filename='proctorx-dialog.css') }}">
    <script src="{{ url_for('static', filename='proctorx-dialog.js') }}" defer></script>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body class="auth-page">
    <span class="orb orb-one"></span><span class="orb orb-two"></span><span class="orb orb-three"></span>
    <main class="auth-layout registration-layout">
        <section class="auth-aside">
            <a href="/login" class="brand" aria-label="ProctorX home"><img class="brand-logo" src="{{ url_for('static', filename='proctorx-logo.png', v='3') }}" alt=""><span>Proctor<em>X</em></span></a>
            <div class="aside-copy">
                <div class="aside-kicker">Set up your profile</div>
                <h1>Your next assessment starts here.</h1>
                <p>Create a verified student profile once. Your profile photo is used to make face verification more reliable during every secure attempt.</p>
            </div>
            <div class="assurance"><span class="assurance-dot"></span>Profile data stays linked to your secure account</div>
        </section>
        <section class="auth-content">
            <div class="auth-card">
                <div class="form-eyebrow">Student registration</div>
                <h2>Create your account</h2>
                <p class="form-intro">Use your official roll number and choose the semester you are currently studying.</p>
                <form id="regForm" enctype="multipart/form-data">
                    <div class="form-grid">
                        <div class="field"><label for="name">Full name</label><input id="name" type="text" name="name" placeholder="Your full name" required></div>
                        <div class="field"><label for="userid">Roll number</label><input id="userid" type="text" name="userid" maxlength="10" placeholder="10 characters" required></div>
                    </div>
                    <div class="field"><label for="email">Email address</label><input id="email" type="email" name="email" placeholder="you@example.com" autocomplete="email" required></div>
                    <div class="branch-section">
                        <p>Select your branch</p>
                        <div class="branch-grid">
                            <label><input type="checkbox" class="branch-cb" name="branch" value="CSE"> CSE</label><label><input type="checkbox" class="branch-cb" name="branch" value="CSE-AI&ML"> CSE (AI & ML)</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="CSE-DS"> CSE (DS)</label><label><input type="checkbox" class="branch-cb" name="branch" value="IT"> IT</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="ECE"> ECE</label><label><input type="checkbox" class="branch-cb" name="branch" value="EEE"> EEE</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="CIVIL"> Civil</label><label><input type="checkbox" class="branch-cb" name="branch" value="MECH"> Mechanical</label>
                            <label><input type="checkbox" class="branch-cb" name="branch" value="MCT"> MCT</label><label><input type="checkbox" class="branch-cb" name="branch" value="MET"> MET</label>
                        </div>
                    </div>
                    <div class="form-grid">
                        <div class="field"><label for="semester">Current semester</label><select id="semester" name="semester" required><option value="" selected disabled>Select semester</option><option value="1-1">1st year, semester 1</option><option value="1-2">1st year, semester 2</option><option value="2-1">2nd year, semester 1</option><option value="2-2">2nd year, semester 2</option><option value="3-1">3rd year, semester 1</option><option value="3-2">3rd year, semester 2</option><option value="4-1">4th year, semester 1</option><option value="4-2">4th year, semester 2</option></select></div>
                        <div class="field"><label for="phone">Phone number</label><input id="phone" type="text" name="phone" placeholder="Registered phone number" required></div>
                    </div>
                    <div class="field"><label for="password">Create password</label><input id="password" type="password" name="password" placeholder="At least 8 characters" oninput="checkStrength(this.value)" required></div>
                    <div class="meter-container"><div id="strength-bar"></div></div>
                    <button class="text-button suggest-link" type="button" onclick="suggestPassword()">Suggest a strong password</button>
                    <div class="branch-section recovery-section">
                        <p>Choose password recovery methods</p>
                        <div class="branch-grid">
                            <label><input type="checkbox" name="recovery_methods" value="phone" checked> Verify with registered phone</label>
                            <label><input type="checkbox" name="recovery_methods" value="email" checked> Receive OTP by email</label>
                        </div>
                    </div>
                    <div class="photo-section">
                        <p>Profile photo required for face verification</p>
                        <div class="photo-actions"><input type="file" id="profile-pic-input" name="profile_pic" accept="image/png,image/jpeg" hidden><button type="button" class="photo-btn" onclick="profilePicInput.click()">Upload photo</button><button type="button" class="photo-btn" onclick="openCameraModal()">Use camera</button></div>
                        <div id="photo-file-name" class="photo-name">Upload a clear, front-facing image.</div><img id="photo-preview" class="photo-preview" alt="Selected profile preview">
                    </div>
                    <button class="primary-button proctorx-wobbly proctorx-btn-loading" type="submit">Create ProctorX account</button>
                </form>
                <div class="form-footer">Already registered? <a href="/login">Back to sign in</a></div>
            </div>
        </section>
    </main>
    <div id="camera-modal"><div class="camera-card"><h3>Capture profile photo</h3><p>Keep your face centered in a bright, clear frame.</p><video id="camera-stream" autoplay playsinline muted></video><canvas id="camera-canvas" hidden></canvas><div class="camera-actions"><button type="button" class="photo-btn" onclick="capturePhoto()">Capture photo</button><button type="button" class="photo-btn" onclick="closeCameraModal()">Cancel</button></div></div></div>
    <script>
        let cameraStream = null;
        const profilePicInput = document.getElementById('profile-pic-input');
        const photoPreview = document.getElementById('photo-preview');
        const photoFileName = document.getElementById('photo-file-name');
        const cameraModal = document.getElementById('camera-modal');
        const cameraVideo = document.getElementById('camera-stream');
        const cameraCanvas = document.getElementById('camera-canvas');
        document.querySelectorAll('.branch-cb').forEach((checkbox) => checkbox.addEventListener('change', () => { if (checkbox.checked) document.querySelectorAll('.branch-cb').forEach((other) => { if (other !== checkbox) other.checked = false; }); }));
        document.getElementById('userid').addEventListener('input', function () { this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, ''); });
        function checkStrength(password) { let score = 0; if (password.length >= 8) score += 25; if (/[A-Z]/.test(password)) score += 25; if (/[0-9]/.test(password)) score += 25; if (/[^A-Za-z0-9]/.test(password)) score += 25; const bar = document.getElementById('strength-bar'); bar.style.width = `${score}%`; bar.style.background = score < 50 ? '#ff839d' : score < 100 ? '#ffd36c' : '#72f4c8'; }
        function suggestPassword() { const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'; const password = Array.from({ length: 12 }, () => chars[Math.floor(Math.random() * chars.length)]).join(''); document.getElementById('password').value = password; checkStrength(password); }
        function updatePhotoPreview(file, label) { if (!file) return; photoFileName.textContent = label || file.name; const reader = new FileReader(); reader.onload = () => { photoPreview.src = reader.result; photoPreview.style.display = 'block'; }; reader.readAsDataURL(file); }
        profilePicInput.addEventListener('change', () => updatePhotoPreview(profilePicInput.files[0]));
        async function openCameraModal() { try { cameraStream = await navigator.mediaDevices.getUserMedia({ video: true }); cameraVideo.srcObject = cameraStream; cameraModal.style.display = 'flex'; } catch { await proctorxAlert('Camera access was denied or is unavailable on this device.', { type: 'warning', title: 'Camera access unavailable' }); } }
        function closeCameraModal() { if (cameraStream) cameraStream.getTracks().forEach((track) => track.stop()); cameraStream = null; cameraVideo.srcObject = null; cameraModal.style.display = 'none'; }
        function capturePhoto() { if (!cameraVideo.videoWidth) return; cameraCanvas.width = cameraVideo.videoWidth; cameraCanvas.height = cameraVideo.videoHeight; cameraCanvas.getContext('2d').drawImage(cameraVideo, 0, 0); cameraCanvas.toBlob((blob) => { if (!blob) return; const file = new File([blob], 'profile-photo.jpg', { type: 'image/jpeg' }); const transfer = new DataTransfer(); transfer.items.add(file); profilePicInput.files = transfer.files; updatePhotoPreview(file, 'Photo captured from camera'); closeCameraModal(); }, 'image/jpeg', .92); }
        document.getElementById('regForm').addEventListener('submit', async (event) => { event.preventDefault(); const formData = new FormData(event.currentTarget); if (!formData.get('branch')) return proctorxAlert('Select one branch before creating your account.', { type: 'warning', title: 'Branch required' }); if (!formData.getAll('recovery_methods').length) return proctorxAlert('Choose at least one password recovery method.', { type: 'warning', title: 'Recovery method required' }); if (!profilePicInput.files.length) return proctorxAlert('Upload or capture a profile photo for face verification.', { type: 'warning', title: 'Profile photo required' }); const response = await fetch('/register_user', { method: 'POST', body: formData }); const data = await response.json(); await proctorxAlert(data.message, { type: data.status === 'success' ? 'success' : 'danger', title: data.status === 'success' ? 'Account created' : 'Registration could not continue' }); if (data.status === 'success') window.location.href = '/login'; });
        window.addEventListener('beforeunload', closeCameraModal);
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Student Portal | Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='tilt-effects.css') }}">
    <script src="{{ url_for('static', filename='tilt-effects.js') }}" defer></script>
    <style>
        :root { --primary: #23a6d5; --sidebar: #1e1e2f; --bg: #f4f7f6; --danger: #e73c7e; }
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        body { background: var(--bg); display: flex; min-height: 100vh; }

        #side-nav { width: 280px; background: var(--sidebar); color: white; padding: 30px 20px; position: fixed; height: 100vh; display: flex; flex-direction: column; }
        .nav-link { padding: 15px; color: #aaa; text-decoration: none; border-radius: 10px; margin-bottom: 10px; display: block; font-weight: 400; }
        .nav-link.active { background: rgba(255,255,255,0.1); color: white; }

        #content { margin-left: 280px; flex: 1; padding: 40px; }
        .panel { background: white; padding: 30px; border-radius: 25px; box-shadow: 0 10px 30px rgba(0,0,0,0.05); }

        .exam-card { border: 1px solid #f0f0f0; padding: 25px; border-radius: 20px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; transition: 0.3s; }
        .locked { opacity: 0.5; filter: grayscale(1); background: #fafafa; cursor: not-allowed; }
        .unlocked:hover { border-color: var(--primary); box-shadow: 0 5px 15px rgba(35, 166, 213, 0.1); }

        .btn-start { background: var(--primary); color: white; padding: 12px 30px; border-radius: 50px; text-decoration: none; font-weight: 600; box-shadow: 0 4px 15px rgba(35, 166, 213, 0.2); }
        .lock-badge { background: #eee; padding: 8px 15px; border-radius: 50px; font-size: 0.8rem; color: #888; }
    </style>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body>
    <div id="side-nav">
        <div style="font-size:1.5rem; font-weight:600; margin-bottom:40px;">🛡️ Student Portal</div>
        <a class="nav-link active">My Assessments</a>
        <a href="/logout" style="margin-top:auto; color:var(--danger); text-decoration:none; padding:15px;">Logout</a>
    </div>

    <div id="content">
        <h1>Welcome, {{ session['name'] }}</h1>
        <p style="color: #888; margin-bottom: 30px;">Semester Group: {{ current_sem }}</p>

        <div class="panel">
            {% for g in range(1, 5) %}
            <div class="exam-card {% if g == group_id %}unlocked{% else %}locked{% endif %}">
                <div>
                    <h3 style="color: #333;">Year {{ g }} Final Assessment</h3>
                    <p style="font-size: 0.85rem; color: #777;">Semester Coverage: {{ (g*2)-1 }} & {{ g*2 }} | 30 Questions | 50 Marks</p>
                    <p style="font-size: 0.8rem; color: #999; margin-top: 6px;">Pattern: 10 MCQs, 10 True/False, 10 Fill in the Blanks</p>
                </div>
                
                {% if g == group_id %}
                <a href="/exam/{{ g }}" class="btn-start proctorx-wobbly">Start Now</a>
                {% else %}
                <div class="lock-badge">🔒 Locked</div>
                {% endif %}
            </div>
            {% endfor %}
        </div>
    </div>

<button class="proctorx-fab" type="button" aria-label="Help" onclick="alert('Support center coming soon!')">
    <svg viewBox="0 0 24 24" aria-hidden="true" fill="currentColor">
        <path d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z"/>
    </svg>
</button>

</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Portal | Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ url_for('static', filename='tilt-effects.css') }}">
    <script src="{{ url_for('static', filename='tilt-effects.js') }}" defer></script>
    <script>
        const savedTheme = localStorage.getItem('portal-theme');
        const preferredTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
        document.documentElement.dataset.theme = savedTheme || preferredTheme;
    </script>
    <style>
        :root {
            --primary: #167fe0;
            --sidebar: #0b2342;
            --bg: #edf5ff;
            --danger: #d84d70;
            --panel: rgba(255,255,255,0.84);
            --text: #12253c;
            --muted: #60738d;
            --nav-muted: #c3d5e9;
            --card-border: rgba(93,132,178,0.2);
            --locked-bg: rgba(20,68,116,0.045);
            --lock-badge-bg: rgba(20,68,116,0.08);
            --lock-badge-text: #60738d;
            --input-bg: #f7fbff;
            --input-border: rgba(93,132,178,0.24);
            --overlay: rgba(6,23,45,0.5);
        }

        html[data-theme='dark'] {
            --primary: #4ee6ff;
            --sidebar: #071126;
            --bg: #061426;
            --panel: rgba(7, 20, 39, 0.78);
            --text: #eef4ff;
            --muted: #9eb0c6;
            --nav-muted: #93a2b8;
            --card-border: rgba(137, 160, 188, 0.18);
            --locked-bg: rgba(255, 255, 255, 0.04);
            --lock-badge-bg: rgba(255, 255, 255, 0.08);
            --lock-badge-text: #c5d0df;
            --input-bg: rgba(255, 255, 255, 0.05);
            --input-border: rgba(137, 160, 188, 0.22);
            --overlay: rgba(3, 8, 15, 0.74);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; -webkit-tap-highlight-color: transparent; }
        html, body { height: 100%; }
        body { background: radial-gradient(circle at 12% 10%, rgba(40,148,239,.18), transparent 24rem), radial-gradient(circle at 88% 82%, rgba(51,197,210,.12), transparent 28rem), linear-gradient(145deg, #f7fbff 0%, #edf5ff 52%, #e4effd 100%); display: flex; min-height: 100vh; height: 100vh; color: var(--text); overflow: hidden; }
        html[data-theme='dark'] body { background: radial-gradient(circle at 14% 12%, rgba(61,168,255,.24), transparent 23rem), radial-gradient(circle at 86% 82%, rgba(135,87,255,.18), transparent 28rem), linear-gradient(130deg, #07192f 0%, #071126 45%, #100d2d 100%); }

        #side-nav { width: 280px; background: linear-gradient(180deg, #0d315d, #081c38); color: white; padding: 30px 20px; position: fixed; top: 0; left: 0; height: 100vh; display: flex; flex-direction: column; overflow-y: auto; border-right:1px solid rgba(180,214,255,.1); }
        html[data-theme='dark'] #side-nav { background: linear-gradient(180deg, rgba(7,25,47,.96), rgba(7,17,38,.96)); }
        .brand { font-size:1.5rem; font-weight:600; margin-bottom:24px; }
        .nav-link { padding: 15px; color: var(--nav-muted); text-decoration: none; border-radius: 10px; margin-bottom: 10px; display: block; font-weight: 400; }
        .nav-link.active { background: rgba(255,255,255,0.1); color: white; }
        .side-bottom { margin-top:auto; display:flex; flex-direction:column; gap:12px; }
        .profile-trigger, .theme-toggle { padding: 12px 14px; border: 1px solid rgba(255,255,255,0.14); border-radius: 16px; background: rgba(255,255,255,0.08); color: white; cursor: pointer; font-weight: 600; }
        .profile-trigger { display:flex; align-items:center; gap:12px; text-align:left; }
        .profile-trigger { text-decoration: none; }
        .profile-avatar, .modal-avatar { width: 44px; height: 44px; border-radius: 50%; overflow:hidden; background: rgba(255,255,255,0.12); display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .modal-avatar { width: 72px; height: 72px; font-size: 1.4rem; }
        .profile-avatar img, .modal-avatar img { width:100%; height:100%; object-fit:cover; display:block; }
        .avatar-fallback { width:100%; height:100%; display:flex; align-items:center; justify-content:center; font-weight:700; }
        .profile-meta small { display:block; color: var(--nav-muted); font-weight:400; margin-top:2px; }
        .logout-link { color:var(--danger); text-decoration:none; padding:15px; }

        #content { margin-left: 280px; flex: 1; height: 100vh; overflow-y: auto; padding: 40px; }
        .page-subtitle { color: var(--muted); margin-bottom: 30px; }
        .panel { background: var(--panel); padding: 30px; border-radius: 25px; border:1px solid var(--card-border); box-shadow: 0 22px 54px rgba(25,66,109,.12), inset 0 1px 0 rgba(255,255,255,.5); backdrop-filter:blur(20px); }
        html[data-theme='dark'] .panel { box-shadow: 0 28px 70px rgba(0,0,0,.25), inset 0 1px 0 rgba(255,255,255,.05); }

        .exam-card { border: 1px solid var(--card-border); padding: 25px; border-radius: 20px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; transition: 0.3s; background: transparent; }
        .exam-info h3 { color: var(--text); }
        .exam-meta, .exam-pattern { color: var(--muted); }
        .exam-meta { font-size: 0.85rem; }
        .exam-pattern { margin-top: 6px; font-size: 0.8rem; }
        .locked { opacity: 0.6; background: var(--locked-bg); cursor: not-allowed; }
        .unlocked:hover { border-color: var(--primary); box-shadow: 0 5px 15px rgba(35, 166, 213, 0.1); }

        .btn-start { background: linear-gradient(100deg, #2cc7e8, #538cff); color: #061426; padding: 12px 30px; border-radius: 50px; text-decoration: none; font-weight: 700; box-shadow: 0 14px 26px rgba(78,183,255,.24); }
        html[data-theme='dark'] .btn-start { background: linear-gradient(100deg, #4ee6ff, #8ca4ff); }
        .lock-badge { background: var(--lock-badge-bg); padding: 8px 15px; border-radius: 50px; font-size: 0.8rem; color: var(--lock-badge-text); }

        .section-block { margin-top: 34px; }
        .section-block h2 { margin-bottom: 8px; }
        .section-copy { color: var(--muted); margin-bottom: 18px; line-height: 1.6; }
        .stats-grid, .split-grid { display: grid; gap: 18px; }
        .stats-grid { grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); margin-bottom: 18px; }
        .split-grid { grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); }
        .stat-tile { background: var(--panel); border-radius: 20px; padding: 20px; box-shadow: 0 10px 24px rgba(0,0,0,0.04); }
        .stat-label { color: var(--muted); font-size: 0.82rem; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 8px; }
        .stat-value { font-size: 2rem; font-weight: 700; }
        .stat-subtext { color: var(--muted); margin-top: 8px; font-size: 0.9rem; }
        .trend-up { color: #18a07f; }
        .trend-down { color: #cc4665; }
        .leaderboard-table, .attempt-table { width: 100%; border-collapse: collapse; }
        .leaderboard-table th, .leaderboard-table td, .attempt-table th, .attempt-table td { text-align: left; padding: 12px 10px; border-bottom: 1px solid var(--card-border); }
        .leaderboard-table th, .attempt-table th { color: var(--muted); font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.05em; }
        .rank-badge { display: inline-flex; align-items: center; justify-content: center; min-width: 34px; height: 34px; border-radius: 999px; background: rgba(35, 166, 213, 0.14); color: var(--primary); font-weight: 700; }
        .chart-shell { height: 280px; }
        .chart-shell canvas { width: 100% !important; height: 100% !important; }
        .topic-list { display: grid; gap: 12px; }
        .topic-card { border: 1px solid var(--card-border); border-radius: 16px; padding: 16px; background: transparent; }
        .topic-meta { display:flex; justify-content:space-between; gap:12px; align-items:center; margin-bottom: 8px; }
        .topic-score { font-weight: 700; color: #cc4665; }
        .achievement-grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap:14px; }
        .achievement-card { border:1px solid var(--card-border); border-radius:18px; padding:18px; background:linear-gradient(180deg, rgba(35,166,213,0.08), transparent); }
        .achievement-card strong { display:block; margin-bottom:8px; }
        .recommendation-card { border-radius:20px; padding:20px; background:linear-gradient(135deg, rgba(35,166,213,0.12), rgba(231,60,126,0.08)); border:1px solid var(--card-border); }
        .insight-grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap:16px; margin-top:18px; }
        .insight-card { border:1px solid var(--card-border); border-radius:18px; padding:18px; background:transparent; }
        .count-up { display:inline-block; }
        .status-banner { background: var(--panel); border-radius: 20px; padding: 18px 20px; margin-bottom: 18px; box-shadow: 0 10px 24px rgba(0,0,0,0.04); display:flex; justify-content:space-between; gap:16px; flex-wrap:wrap; }
        .pill { display:inline-flex; padding: 7px 12px; border-radius: 999px; font-size: 0.8rem; font-weight: 700; }
        .pill.low { background: rgba(24, 160, 127, 0.14); color: #18a07f; }
        .pill.medium { background: rgba(244, 169, 0, 0.16); color: #c87d00; }
        .pill.high { background: rgba(231, 60, 126, 0.14); color: #cc4665; }
        .pill.pending { background: rgba(35, 166, 213, 0.14); color: var(--primary); }
        .report-link { display:inline-flex; align-items:center; gap:8px; padding: 11px 14px; border-radius: 14px; background: rgba(35, 166, 213, 0.12); color: var(--primary); text-decoration:none; font-weight: 600; }
        .empty-state { background: var(--panel); border-radius: 20px; padding: 22px; color: var(--muted); line-height: 1.6; }

        #profile-modal { position: fixed; inset: 0; background: var(--overlay); display: none; align-items: center; justify-content: center; padding: 24px; z-index: 1000; }
        #profile-modal.is-open { display: flex; }
        .profile-modal-card { width: min(760px, 100%); background: var(--panel); border-radius: 24px; padding: 28px; box-shadow: 0 18px 42px rgba(0,0,0,0.16); }
        .modal-head { display:flex; justify-content:space-between; gap:20px; align-items:flex-start; margin-bottom: 20px; }
        .modal-head p { color: var(--muted); margin-top: 8px; line-height: 1.6; }
        .modal-close { border:none; background:transparent; color: var(--muted); font-size: 1.6rem; cursor:pointer; }
        .profile-summary { display:flex; gap:16px; align-items:center; margin-bottom: 22px; }
        .summary-copy p { color: var(--muted); margin-top: 6px; }
        .profile-grid { display:grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
        .field { display:flex; flex-direction:column; gap:8px; }
        .field label { font-size: 0.9rem; font-weight: 600; }
        .field input, .field select { width:100%; padding:13px 14px; border-radius: 14px; border:1px solid var(--input-border); background: var(--input-bg); color: var(--text); }
        .field input[disabled] { opacity: 0.75; cursor: not-allowed; }
        .field.full { grid-column: 1 / -1; }
        .profile-note { color: var(--muted); font-size: 0.85rem; line-height: 1.6; }
        .modal-actions { display:flex; justify-content:flex-end; gap:12px; margin-top: 22px; }
        .btn-secondary, .btn-primary { border:none; border-radius: 14px; padding: 12px 18px; cursor:pointer; font-weight: 600; }
        .btn-secondary { background: rgba(137, 160, 188, 0.18); color: var(--text); }
        .btn-primary { background: var(--primary); color: white; }
        .profile-message { display:none; margin-top: 16px; padding: 12px 14px; border-radius: 14px; font-size: 0.9rem; }
        .profile-message.success { display:block; background: rgba(35, 213, 171, 0.14); color: #18a07f; }
        .profile-message.error { display:block; background: rgba(231, 60, 126, 0.14); color: #cc4665; }

        @media (max-width: 980px) {
            body { flex-direction: column; height: auto; overflow: auto; }
            #side-nav {
                width: 100%;
                position: static;
                height: auto;
                padding: 22px 18px;
                overflow: visible;
            }
            .brand { margin-bottom: 12px; }
            .side-bottom { margin-top: 0; }
            #content {
                margin-left: 0;
                width: 100%;
                height: auto;
                overflow: visible;
                padding: 24px 18px 30px;
            }
            .exam-card {
                flex-direction: column;
                align-items: flex-start;
                gap: 16px;
            }
            .btn-start, .lock-badge {
                width: 100%;
                text-align: center;
            }
            .leaderboard-table, .attempt-table {
                display: block;
                overflow-x: auto;
                white-space: nowrap;
            }
        }

        @media (max-width: 760px) {
            .profile-grid { grid-template-columns: 1fr; }
            .modal-head, .profile-summary, .modal-actions { flex-direction: column; }
            .modal-actions { align-items: stretch; }
            .leaderboard-table, .attempt-table { font-size: 0.88rem; }
            .stats-grid, .split-grid { grid-template-columns: 1fr; }
            .status-banner { padding: 16px; }
            .profile-trigger, .theme-toggle, .logout-link { width: 100%; }
            .profile-trigger { justify-content: flex-start; }
            .panel, .stat-tile, .empty-state { padding: 18px; }
            h1 { font-size: 1.8rem; }
        }

        @media (max-width: 520px) {
            #content { padding: 18px 14px 24px; }
            #side-nav { padding: 18px 14px; }
            .nav-link { margin-bottom: 4px; padding: 13px 14px; }
            .exam-card { padding: 18px; }
            .report-link { width: 100%; justify-content: center; }
            .stat-value { font-size: 1.6rem; }
            #profile-modal { padding: 12px; }
            .profile-modal-card { max-height: calc(100dvh - 24px); overflow-y: auto; padding: 20px; }
            .btn-primary, .btn-secondary { min-height: 46px; }
        }
        body.page-ready { opacity: 1; transform: translateY(0); }
        body.page-exit { opacity: 0; transform: translateY(8px); }
        body { transition: opacity 0.28s ease, transform 0.28s ease; }
        @media (prefers-reduced-motion: reduce) {
            body, body.page-ready, body.page-exit { transition: none; transform: none; opacity: 1; }
        }
    </style>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body>
    <div id="side-nav">
        <div class="brand">Student Portal</div>
        <a class="nav-link active">My Assessments</a>
        <div class="side-bottom">
            <a href="/student/profile" id="profile-trigger" class="profile-trigger">
                <div class="profile-avatar">
                    <img
                        id="sidebar-profile-image"
                        alt="Profile picture"
                        {% if student_profile.has_profile_pic %}
                        src="{{ url_for('static', filename='profiles/' + student_profile.profile_pic) }}"
                        {% else %}
                        style="display:none;"
                        {% endif %}
                        onerror="handleAvatarError('sidebar-profile-image', 'sidebar-profile-fallback')"
                    >
                    <div id="sidebar-profile-fallback" class="avatar-fallback" {% if student_profile.has_profile_pic %}style="display:none;"{% endif %}>
                        {{ (student_profile.name[:1] if student_profile.name else 'S') | upper }}
                    </div>
                </div>
                <div class="profile-meta">
                    <strong>{{ student_profile.name }}</strong>
                    <small>View or edit profile</small>
                </div>
            </a>
            <button type="button" class="theme-toggle" onclick="toggleTheme()">Dark Mode</button>
            <a href="/logout" class="logout-link">Logout</a>
        </div>
    </div>

    <div id="content">
        <h1>Welcome, {{ session['name'] }}</h1>
        <p class="page-subtitle">Semester Group: {{ current_sem }} | Year {{ group_id }} exam is currently unlocked.</p>

        <div class="status-banner">
            <div>
                <strong>Attempt Control</strong>
                <p class="section-copy" style="margin:6px 0 0;">{{ attempt_summary.attempts_used }} used out of {{ attempt_summary.max_attempts }} attempt{{ '' if attempt_summary.max_attempts == 1 else 's' }}. {% if attempt_summary.allowed %}You can start the current year exam now.{% else %}{{ attempt_summary.reason }}{% endif %}</p>
            </div>
            <div>
                <strong>Latest Risk</strong>
                <p style="margin-top:8px;">
                    <span class="pill {{ latest_risk.level|lower }}">{{ latest_risk.level }} Risk</span>
                    <span class="pill pending">{{ latest_risk.score }} Score</span>
                    <span class="pill pending">{{ latest_risk.decision|replace('_', ' ')|title }}</span>
                </p>
                {% if latest_result_id %}
                <p style="margin-top:10px;"><a class="report-link" href="/student/result/{{ latest_result_id }}/pdf">Download Latest PDF Report</a></p>
                {% endif %}
            </div>
        </div>

        <div class="section-block">
            <h2>Achievement Badges</h2>
            <p class="section-copy">Quick highlights from your recent results, rank, and proctoring history.</p>
            {% if achievement_badges %}
            <div class="achievement-grid">
                {% for badge in achievement_badges %}
                <div class="achievement-card">
                    <strong>{{ badge.title }}</strong>
                    <div class="stat-subtext">{{ badge.description }}</div>
                </div>
                {% endfor %}
            </div>
            {% else %}
            <div class="empty-state">Submit a few attempts to unlock progress badges, clean-attempt milestones, and score-improvement highlights.</div>
            {% endif %}
        </div>

        <div class="panel">
            {% for g in range(1, 5) %}
            <div class="exam-card {% if g == group_id %}unlocked{% else %}locked{% endif %}">
                <div class="exam-info">
                    <h3>Year {{ g }} Final Assessment</h3>
                    <p class="exam-meta">Semester Coverage: {{ (g*2)-1 }} & {{ g*2 }} | 30 Questions | 50 Marks</p>
                    <p class="exam-pattern">Pattern: 10 MCQs, 10 True/False, 10 Fill in the Blanks</p>
                </div>
                
                {% if g == group_id %}
                    {% if attempt_summary.allowed %}
                    <a href="/exam/{{ g }}" class="btn-start proctorx-wobbly">Start Now</a>
                    {% else %}
                    <div class="lock-badge">{{ attempt_summary.reason }}</div>
                    {% endif %}
                {% else %}
                <div class="lock-badge">Locked</div>
                {% endif %}
            </div>
            {% endfor %}
        </div>

        <div class="section-block">
            <h2>Rank / Leaderboard</h2>
            <p class="section-copy">See where you stand compared with other students based on average exam performance.</p>

            {% if student_rank %}
            <div class="stats-grid">
                <div class="stat-tile">
                    <div class="stat-label">Your Rank</div>
                    <div class="stat-value">#{{ student_rank.rank }}</div>
                    <div class="stat-subtext">Based on average score across attempts.</div>
                </div>
                <div class="stat-tile">
                    <div class="stat-label">Average Score</div>
                    <div class="stat-value">{{ student_rank.avg_score }}</div>
                    <div class="stat-subtext">Your best score is {{ student_rank.best_score }} / 50.</div>
                </div>
                <div class="stat-tile">
                    <div class="stat-label">Attempts Count</div>
                    <div class="stat-value">{{ student_rank.attempts }}</div>
                    <div class="stat-subtext">Each new result can improve your leaderboard position.</div>
                </div>
            </div>

            <div class="panel">
                <table class="leaderboard-table">
                    <thead>
                        <tr>
                            <th>Rank</th>
                            <th>Name</th>
                            <th>Average</th>
                            <th>Best Score</th>
                            <th>Attempts</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for entry in leaderboard %}
                        <tr>
                            <td><span class="rank-badge">{{ entry.rank }}</span></td>
                            <td>
                                {{ entry.name }}
                                {% if entry.student_id == student_profile.id %}
                                <strong>(You)</strong>
                                {% endif %}
                            </td>
                            <td>{{ entry.avg_score }}</td>
                            <td>{{ entry.best_score }} / 50</td>
                            <td>{{ entry.attempts }}</td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
            {% else %}
            <div class="empty-state">Leaderboard will appear after exam results are available. Once you submit your first paper, your rank and the top performers will be shown here.</div>
            {% endif %}
        </div>

        <div class="section-block">
            <h2>Performance Analytics</h2>
            <p class="section-copy">Track your past scores and identify the question areas that need more attention.</p>

            {% if attempts_count > 0 %}
            <div class="stats-grid">
                <div class="stat-tile">
                    <div class="stat-label">Attempts</div>
                    <div class="stat-value count-up" data-count="{{ attempts_count }}">{{ attempts_count }}</div>
                    <div class="stat-subtext">Your total recorded exam submissions.</div>
                </div>
                <div class="stat-tile">
                    <div class="stat-label">Average Score</div>
                    <div class="stat-value count-up" data-count="{{ average_score }}">{{ average_score }}</div>
                    <div class="stat-subtext">Across all saved exam attempts.</div>
                </div>
                <div class="stat-tile">
                    <div class="stat-label">Best Score</div>
                    <div class="stat-value count-up" data-count="{{ best_score }}">{{ best_score }}</div>
                    <div class="stat-subtext">Your highest score so far out of 50.</div>
                </div>
                <div class="stat-tile">
                    <div class="stat-label">Latest Trend</div>
                    <div class="stat-value {% if latest_trend > 0 %}trend-up{% elif latest_trend < 0 %}trend-down{% endif %}">
                        {% if latest_trend > 0 %}+{% endif %}{{ latest_trend }}
                    </div>
                    <div class="stat-subtext">Difference between your latest two attempts.</div>
                </div>
            </div>

            <div class="recommendation-card">
                <strong>Retake Recommendation</strong>
                <p class="section-copy" style="margin:8px 0 0;">{{ retake_recommendation }}</p>
            </div>

            <div class="insight-grid">
                <div class="insight-card">
                    <div class="stat-label">Strongest Topic</div>
                    {% if strongest_topic %}
                    <div class="stat-value">{{ strongest_topic.title }}</div>
                    <div class="stat-subtext">{{ strongest_topic.accuracy }}% accuracy across {{ strongest_topic.attempts }} attempt{{ '' if strongest_topic.attempts == 1 else 's' }}.</div>
                    {% else %}
                    <div class="stat-subtext">Strongest-topic insights will appear after section-wise analyses are stored.</div>
                    {% endif %}
                </div>
                <div class="insight-card">
                    <div class="stat-label">Weakest Topic</div>
                    {% if weakest_topic %}
                    <div class="stat-value">{{ weakest_topic.title }}</div>
                    <div class="stat-subtext">{{ weakest_topic.accuracy }}% accuracy so far. This is the best place to focus next.</div>
                    {% else %}
                    <div class="stat-subtext">Weakest-topic insights will appear after section-wise analyses are stored.</div>
                    {% endif %}
                </div>
            </div>

            <div class="split-grid">
                <div class="panel">
                    <h3 style="margin-bottom: 8px;">Past Scores</h3>
                    <p class="section-copy" style="margin-bottom: 14px;">Your score trend across recorded attempts.</p>
                    <div class="chart-shell">
                        <canvas id="scoreHistoryChart"></canvas>
                    </div>
                </div>

                <div class="panel">
                    <h3 style="margin-bottom: 8px;">Weak Topics</h3>
                    <p class="section-copy" style="margin-bottom: 14px;">These are your lowest-performing sections based on saved analyses.</p>
                    {% if weak_topics %}
                    <div class="topic-list">
                        {% for topic in weak_topics %}
                        <div class="topic-card">
                            <div class="topic-meta">
                                <strong>{{ topic.title }}</strong>
                                <span class="topic-score">{{ topic.accuracy }}%</span>
                            </div>
                            <div class="stat-subtext">{{ topic.earned }} / {{ topic.possible }} marks across {{ topic.attempts }} attempt{{ '' if topic.attempts == 1 else 's' }}</div>
                        </div>
                        {% endfor %}
                    </div>
                    {% else %}
                    <div class="empty-state">Weak-topic analysis will appear for new attempts saved with section-wise exam analytics.</div>
                    {% endif %}
                </div>
            </div>

            <div class="panel" style="margin-top: 18px;">
                <h3 style="margin-bottom: 8px;">Recent Attempts</h3>
                <p class="section-copy" style="margin-bottom: 14px;">Your latest saved exam results.</p>
                <table class="attempt-table">
                    <thead>
                        <tr>
                            <th>Year Exam</th>
                            <th>Score</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for attempt in recent_attempts %}
                        <tr>
                            <td>Year {{ attempt.year_group }}</td>
                            <td>{{ attempt.score }} / {{ attempt.total }}</td>
                            <td>{{ attempt.date }}</td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
            {% else %}
            <div class="empty-state">No performance analytics yet. Submit an exam and this section will show your score trend, recent attempts, and weak-topic summary.</div>
            {% endif %}
        </div>

        <div class="section-block">
            <h2>Improvement Suggestions</h2>
            <p class="section-copy">Suggestions are based on your latest saved section analysis.</p>
            {% if improvement_suggestions %}
            <div class="topic-list">
                {% for suggestion in improvement_suggestions %}
                <div class="topic-card">
                    <div class="topic-meta">
                        <strong>{{ suggestion.section }}</strong>
                        <span class="topic-score">{{ suggestion.score_text }}</span>
                    </div>
                    <div class="stat-subtext">{{ suggestion.message }}</div>
                </div>
                {% endfor %}
            </div>
            {% else %}
            <div class="empty-state">Submit an exam to receive section-wise improvement hints and revision guidance.</div>
            {% endif %}
        </div>
    </div>

    <div id="profile-modal" aria-hidden="true">
        <div class="profile-modal-card">
            <div class="modal-head">
                <div>
                    <h2>My Profile</h2>
                    <p>Update your details here. Roll number is fixed, but if you change semester the unlocked exam year will update on refresh.</p>
                </div>
                <button type="button" class="modal-close" onclick="closeProfileModal()">&times;</button>
            </div>

            <div class="profile-summary">
                <div class="modal-avatar">
                    <img
                        id="modal-profile-image"
                        alt="Profile picture"
                        {% if student_profile.has_profile_pic %}
                        src="{{ url_for('static', filename='profiles/' + student_profile.profile_pic) }}"
                        {% else %}
                        style="display:none;"
                        {% endif %}
                        onerror="handleAvatarError('modal-profile-image', 'modal-profile-fallback')"
                    >
                    <div id="modal-profile-fallback" class="avatar-fallback" {% if student_profile.has_profile_pic %}style="display:none;"{% endif %}>
                        {{ (student_profile.name[:1] if student_profile.name else 'S') | upper }}
                    </div>
                </div>
                <div class="summary-copy">
                    <h3>{{ student_profile.name }}</h3>
                    <p>{{ student_profile.id }} | {{ student_profile.branch or 'No branch added yet' }}</p>
                </div>
            </div>

            <form id="profile-form">
                <div class="profile-grid">
                    <div class="field">
                        <label for="profile-id">Roll Number</label>
                        <input id="profile-id" type="text" value="{{ student_profile.id }}" disabled>
                    </div>
                    <div class="field">
                        <label for="profile-name">Full Name</label>
                        <input id="profile-name" name="name" type="text" value="{{ student_profile.name }}" required>
                    </div>
                    <div class="field">
                        <label for="profile-branch">Branch</label>
                        <input id="profile-branch" name="branch" type="text" value="{{ student_profile.branch }}" required>
                    </div>
                    <div class="field">
                        <label for="profile-semester">Semester</label>
                        <select id="profile-semester" name="semester" required>
                            {% for year in range(1, 5) %}
                            {% for term in range(1, 3) %}
                            <option value="{{ year }}-{{ term }}" {% if student_profile.semester == (year ~ '-' ~ term) %}selected{% endif %}>{{ year }}-{{ term }}</option>
                            {% endfor %}
                            {% endfor %}
                        </select>
                    </div>
                    <div class="field">
                        <label for="profile-phone">Phone Number</label>
                        <input id="profile-phone" name="phone" type="text" value="{{ student_profile.phone }}" required>
                    </div>
                    <div class="field full">
                        <label for="profile-pic">Profile Picture</label>
                        <input id="profile-pic" name="profile_pic" type="file" accept=".png,.jpg,.jpeg" onchange="previewProfilePicture(event)">
                        <p class="profile-note">Supported formats: PNG, JPG, JPEG.</p>
                    </div>
                </div>
                <div id="profile-message" class="profile-message"></div>
                <div class="modal-actions">
                    <button type="button" class="btn-secondary" onclick="closeProfileModal()">Cancel</button>
                    <button type="submit" class="btn-primary proctorx-btn-loading">Save Profile</button>
                </div>
            </form>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        function applyTheme(theme) {
            document.documentElement.dataset.theme = theme;
            localStorage.setItem('portal-theme', theme);
            document.querySelector('.theme-toggle').textContent = theme === 'dark' ? 'Light Mode' : 'Dark Mode';
        }

        function toggleTheme() {
            const nextTheme = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
            applyTheme(nextTheme);
        }

        function openProfileModal() {
            const modal = document.getElementById('profile-modal');
            if (!modal) {
                return;
            }

            modal.classList.add('is-open');
            modal.style.display = 'flex';
            modal.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
        }

        function closeProfileModal() {
            const modal = document.getElementById('profile-modal');
            if (!modal) {
                return;
            }

            modal.classList.remove('is-open');
            modal.style.display = 'none';
            modal.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
        }

        function handleAvatarError(imageId, fallbackId) {
            document.getElementById(imageId).style.display = 'none';
            document.getElementById(fallbackId).style.display = 'flex';
        }

        function setAvatarPreview(imageId, fallbackId, src) {
            const image = document.getElementById(imageId);
            const fallback = document.getElementById(fallbackId);
            image.src = src;
            image.style.display = 'block';
            fallback.style.display = 'none';
        }

        function previewProfilePicture(event) {
            const file = event.target.files && event.target.files[0];
            if (!file) {
                return;
            }

            const previewUrl = URL.createObjectURL(file);
            setAvatarPreview('sidebar-profile-image', 'sidebar-profile-fallback', previewUrl);
            setAvatarPreview('modal-profile-image', 'modal-profile-fallback', previewUrl);
        }

        function showProfileMessage(type, message) {
            const messageBox = document.getElementById('profile-message');
            messageBox.className = `profile-message ${type}`;
            messageBox.textContent = message;
        }

        const profileForm = document.getElementById('profile-form');
        if (profileForm) {
            profileForm.addEventListener('submit', async function(event) {
                event.preventDefault();

                const submitButton = this.querySelector('.btn-primary');
                submitButton.disabled = true;
                submitButton.textContent = 'Saving...';

                try {
                    const response = await fetch('/student/update_profile', {
                        method: 'POST',
                        body: new FormData(this)
                    });
                    const data = await response.json();

                    if (!response.ok || data.status !== 'success') {
                        showProfileMessage('error', data.message || 'Could not update the profile.');
                        return;
                    }

                    showProfileMessage('success', data.message || 'Profile updated successfully.');
                    setTimeout(() => window.location.reload(), 700);
                } catch (error) {
                    showProfileMessage('error', 'A network error occurred while saving the profile.');
                } finally {
                    submitButton.disabled = false;
                    submitButton.textContent = 'Save Profile';
                }
            });
        }

        const profileModal = document.getElementById('profile-modal');
        if (profileModal) {
            profileModal.addEventListener('click', function(event) {
                if (event.target === this) {
                    closeProfileModal();
                }
            });
        }

        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeProfileModal();
            }
        });

        applyTheme(document.documentElement.dataset.theme || 'light');

        const scoreHistoryLabels = {{ score_history_labels | tojson }};
        const scoreHistoryValues = {{ score_history_values | tojson }};
        document.querySelectorAll('.count-up').forEach((node, index) => {
            const target = Number(node.dataset.count || 0);
            if (Number.isNaN(target)) return;
            const decimals = String(node.dataset.count || '').includes('.') ? 1 : 0;
            const duration = 900 + (index * 90);
            const start = performance.now();
            const step = (now) => {
                const progress = Math.min(1, (now - start) / duration);
                const eased = 1 - Math.pow(1 - progress, 3);
                node.textContent = (target * eased).toFixed(decimals).replace(/\.0$/, '');
                if (progress < 1) requestAnimationFrame(step);
                else node.textContent = String(target).replace(/\.0$/, '');
            };
            requestAnimationFrame(step);
        });
        if (window.Chart && scoreHistoryLabels.length) {
            Chart.defaults.color = getComputedStyle(document.documentElement).getPropertyValue('--muted').trim() || '#66768d';
            new Chart(document.getElementById('scoreHistoryChart'), {
                type: 'line',
                data: {
                    labels: scoreHistoryLabels,
                    datasets: [{
                        label: 'Score',
                        data: scoreHistoryValues,
                        borderColor: '#23a6d5',
                        backgroundColor: 'rgba(35, 166, 213, 0.14)',
                        fill: true,
                        tension: 0.35,
                        pointRadius: 4,
                        pointBackgroundColor: '#23a6d5'
                    }]
                },
                options: {
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: {
                            beginAtZero: true,
                            suggestedMax: 50,
                            ticks: { stepSize: 10 },
                            grid: { color: 'rgba(137, 160, 188, 0.18)' }
                        },
                        x: {
                            grid: { display: false }
                        }
                    }
                }
            });
        }
    </script>
    <script>
        (function () {
            const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            const enterPage = () => {
                document.body.classList.add('page-ready');
                document.body.classList.remove('page-exit');
            };
            window.transitionTo = function (url) {
                if (!url) return;
                if (reduceMotion) { window.location.href = url; return; }
                document.body.classList.remove('page-ready');
                document.body.classList.add('page-exit');
                setTimeout(() => { window.location.href = url; }, 220);
            };
            document.addEventListener('click', (event) => {
                const link = event.target.closest('a[href]');
                if (!link) return;
                const href = link.getAttribute('href') || '';
                if (!href || href.startsWith('#') || link.target === '_blank' || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
                const absoluteUrl = new URL(link.href, window.location.href);
                if (absoluteUrl.origin !== window.location.origin) return;
                event.preventDefault();
                transitionTo(absoluteUrl.href);
            });
            window.addEventListener('pageshow', enterPage);
            if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', enterPage);
            else enterPage();
        })();
    </script>

<button class="proctorx-fab" type="button" aria-label="Help" onclick="alert('Support center coming soon!')">
    <svg viewBox="0 0 24 24" aria-hidden="true" fill="currentColor">
        <path d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z"/>
    </svg>
</button>

</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Profile</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script>
        document.documentElement.dataset.theme = localStorage.getItem('portal-theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    </script>
    <link rel="stylesheet" href="{{ url_for('static', filename='tilt-effects.css') }}">
    <script src="{{ url_for('static', filename='tilt-effects.js') }}" defer></script>
    <style>
        :root {
            --primary: #23a6d5;
            --primary-dark: #167da1;
            --bg: #eef4fb;
            --panel: #ffffff;
            --text: #1f2a36;
            --muted: #66768d;
            --border: #d9e3ef;
            --input-bg: #f9fbff;
            --success-bg: rgba(35, 213, 171, 0.14);
            --success-text: #188c71;
            --error-bg: rgba(231, 60, 126, 0.14);
            --error-text: #c53d62;
        }

        html[data-theme='dark'] {
            --primary: #4ee6ff;
            --primary-dark: #8ca4ff;
            --bg: #061426;
            --panel: rgba(7, 20, 39, 0.88);
            --text: #eaf3ff;
            --muted: #a7b6cb;
            --border: rgba(180, 214, 255, 0.18);
            --input-bg: rgba(255,255,255,0.055);
            --success-bg: rgba(114,244,200,0.12);
            --success-text: #72f4c8;
            --error-bg: rgba(255,131,157,0.12);
            --error-text: #ffb6c5;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Poppins', sans-serif; }
        body { background: radial-gradient(circle at 12% 10%, rgba(40,148,239,.18), transparent 24rem), linear-gradient(145deg, #f7fbff 0%, #e9f3ff 100%); color: var(--text); min-height: 100vh; padding: 28px 16px; }
        html[data-theme='dark'] body { background: radial-gradient(circle at 12% 10%, rgba(61,168,255,.27), transparent 24rem), radial-gradient(circle at 88% 82%, rgba(135,87,255,.18), transparent 28rem), linear-gradient(130deg, #07192f 0%, #071126 45%, #100d2d 100%); }
        .shell { max-width: 900px; margin: 0 auto; }
        .page-actions { display:flex; align-items:center; justify-content:space-between; gap:16px; margin-bottom:18px; }
        .back-link { display: inline-flex; align-items: center; gap: 8px; color: var(--primary-dark); text-decoration: none; font-weight: 600; }
        .card { background: var(--panel); border: 1px solid var(--border); border-radius: 28px; box-shadow: 0 18px 44px rgba(15, 44, 77, 0.08); padding: 28px; }
        html[data-theme='dark'] .card { box-shadow: 0 28px 80px rgba(0,0,0,.32), inset 0 1px 0 rgba(255,255,255,.06); backdrop-filter: blur(24px); }
        .card-head { display: flex; justify-content: space-between; gap: 16px; align-items: flex-start; margin-bottom: 24px; }
        .card-head p { color: var(--muted); margin-top: 8px; line-height: 1.6; }
        .profile-band { display: flex; align-items: center; gap: 18px; padding: 18px; border-radius: 22px; background: linear-gradient(135deg, rgba(35, 166, 213, 0.12), rgba(22, 125, 161, 0.08)); margin-bottom: 24px; }
        html[data-theme='dark'] .profile-band { background: linear-gradient(135deg, rgba(78,230,255,.13), rgba(140,164,255,.08)); }
        .avatar { width: 88px; height: 88px; border-radius: 50%; overflow: hidden; background: rgba(35, 166, 213, 0.14); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .avatar img { width: 100%; height: 100%; object-fit: cover; display: block; }
        .avatar-fallback { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: 700; color: var(--primary-dark); }
        .profile-band p { color: var(--muted); margin-top: 6px; }
        .grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
        .field { display: flex; flex-direction: column; gap: 8px; }
        .field.full { grid-column: 1 / -1; }
        .field label { font-weight: 600; font-size: 0.92rem; }
        .field input, .field select { width: 100%; padding: 14px 15px; border-radius: 14px; border: 1px solid var(--border); background: var(--input-bg); color: var(--text); }
        .field input[disabled] { opacity: 0.78; cursor: not-allowed; }
        .note { color: var(--muted); font-size: 0.86rem; line-height: 1.6; }
        .message { display: none; margin-top: 18px; padding: 12px 14px; border-radius: 14px; font-size: 0.92rem; }
        .message.success { display: block; background: var(--success-bg); color: var(--success-text); }
        .message.error { display: block; background: var(--error-bg); color: var(--error-text); }
        .actions { display: flex; justify-content: flex-end; gap: 12px; margin-top: 24px; }
        .btn { border: none; border-radius: 14px; padding: 13px 20px; cursor: pointer; font-weight: 600; text-decoration: none; }
        .btn.secondary { background: rgba(137, 160, 188, 0.2); color: var(--text); }
        .btn.primary { background: var(--primary); color: #fff; }
        .btn.primary:disabled { opacity: 0.7; cursor: wait; }
        .theme-toggle { border:1px solid var(--border); border-radius:14px; padding:10px 14px; color:var(--text); background:var(--input-bg); cursor:pointer; font-weight:600; }

        @media (max-width: 720px) {
            .card { padding: 20px; border-radius: 22px; }
            .card-head, .profile-band, .actions { flex-direction: column; }
            .page-actions { align-items:flex-start; flex-direction:column; }
            .grid { grid-template-columns: 1fr; }
            .actions .btn { width: 100%; text-align: center; }
        }
    </style>
<link rel="stylesheet" href="{{ url_for('static', filename='proctorx-ui.css?v=2') }}">
    <script src="{{ url_for('static', filename='proctorx-ui.js?v=2') }}"></script>
</head>
<body>
    <div class="shell">
        <div class="page-actions"><a class="back-link" href="/student_dashboard">Back to dashboard</a><button class="theme-toggle" type="button" onclick="toggleTheme()">Dark Mode</button></div>

        <div class="card">
            <div class="card-head">
                <div>
                    <h1>My Profile</h1>
                    <p>View and update your student details here. Roll number stays fixed, but your semester and profile photo can be updated.</p>
                </div>
            </div>

            <div class="profile-band">
                <div class="avatar">
                    <img
                        id="profile-preview"
                        alt="Profile picture"
                        {% if student_profile.has_profile_pic %}
                        src="{{ url_for('static', filename='profiles/' + student_profile.profile_pic) }}"
                        {% else %}
                        style="display:none;"
                        {% endif %}
                    >
                    <div id="profile-fallback" class="avatar-fallback" {% if student_profile.has_profile_pic %}style="display:none;"{% endif %}>
                        {{ (student_profile.name[:1] if student_profile.name else 'S') | upper }}
                    </div>
                </div>
                <div>
                    <h2>{{ student_profile.name }}</h2>
                    <p>{{ student_profile.id }} | {{ student_profile.branch or 'No branch added yet' }}</p>
                </div>
            </div>

            <form id="profile-form">
                <div class="grid">
                    <div class="field">
                        <label for="profile-id">Roll Number</label>
                        <input id="profile-id" type="text" value="{{ student_profile.id }}" disabled>
                    </div>
                    <div class="field">
                        <label for="profile-name">Full Name</label>
                        <input id="profile-name" name="name" type="text" value="{{ student_profile.name }}" required>
                    </div>
                    <div class="field">
                        <label for="profile-branch">Branch</label>
                        <input id="profile-branch" name="branch" type="text" value="{{ student_profile.branch }}" required>
                    </div>
                    <div class="field">
                        <label for="profile-semester">Semester</label>
                        <select id="profile-semester" name="semester" required>
                            {% for year in range(1, 5) %}
                            {% for term in range(1, 3) %}
                            <option value="{{ year }}-{{ term }}" {% if student_profile.semester == (year ~ '-' ~ term) %}selected{% endif %}>{{ year }}-{{ term }}</option>
                            {% endfor %}
                            {% endfor %}
                        </select>
                    </div>
                    <div class="field">
                        <label for="profile-phone">Phone Number</label>
                        <input id="profile-phone" name="phone" type="text" value="{{ student_profile.phone }}" required>
                    </div>
                    <div class="field full">
                        <label for="profile-pic">Profile Picture</label>
                        <input id="profile-pic" name="profile_pic" type="file" accept=".png,.jpg,.jpeg">
                        <p class="note">Supported formats: PNG, JPG, JPEG.</p>
                    </div>
                </div>

                <div id="profile-message" class="message"></div>

                <div class="actions">
                    <a class="btn secondary" href="/student_dashboard">Cancel</a>
                    <button type="submit" class="btn primary proctorx-btn-loading">Save Profile</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function toggleTheme() {
            const nextTheme = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
            document.documentElement.dataset.theme = nextTheme;
            localStorage.setItem('portal-theme', nextTheme);
            document.querySelector('.theme-toggle').textContent = nextTheme === 'dark' ? 'Light Mode' : 'Dark Mode';
        }
        document.querySelector('.theme-toggle').textContent = document.documentElement.dataset.theme === 'dark' ? 'Light Mode' : 'Dark Mode';
        function showMessage(type, message) {
            const box = document.getElementById('profile-message');
            box.className = `message ${type}`;
            box.textContent = message;
        }

        document.getElementById('profile-pic').addEventListener('change', function(event) {
            const file = event.target.files && event.target.files[0];
            if (!file) {
                return;
            }

            const preview = document.getElementById('profile-preview');
            const fallback = document.getElementById('profile-fallback');
            preview.src = URL.createObjectURL(file);
            preview.style.display = 'block';
            fallback.style.display = 'none';
        });

        document.getElementById('profile-form').addEventListener('submit', async function(event) {
            event.preventDefault();

            const submitButton = this.querySelector('.btn.primary');
            submitButton.disabled = true;
            submitButton.textContent = 'Saving...';

            try {
                const response = await fetch('/student/update_profile', {
                    method: 'POST',
                    body: new FormData(this)
                });
                const data = await response.json();

                if (!response.ok || data.status !== 'success') {
                    showMessage('error', data.message || 'Could not update the profile.');
                    return;
                }

                showMessage('success', data.message || 'Profile updated successfully.');
                setTimeout(() => {
                    window.location.href = '/student_dashboard';
                }, 700);
            } catch (error) {
                showMessage('error', 'A network error occurred while saving the profile.');
            } finally {
                submitButton.disabled = false;
                submitButton.textContent = 'Save Profile';
            }
        });
    </script>
</body>
</html>
