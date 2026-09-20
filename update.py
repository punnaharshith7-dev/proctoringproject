import os

files = [
    'templates/admin_dashboard.html', 
    'templates/admin_dashboard_stats.html', 
    'templates/exam.html', 
    'templates/exam_structured.html', 
    'templates/student_dashboard.html', 
    'templates/student_dashboard_theme.html', 
    'templates/student_profile.html'
]

fab_html = '''
<button class="proctorx-fab" type="button" aria-label="Help" onclick="alert('Support center coming soon!')">
    <svg viewBox="0 0 24 24" aria-hidden="true" fill="currentColor">
        <path d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z"/>
    </svg>
</button>
'''

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'proctorx-ui.css' not in content:
        content = content.replace('</head>', f'<link rel="stylesheet" href="{{{{ url_for(\'static\', filename=\'proctorx-ui.css\') }}}}">\n    <script src="{{{{ url_for(\'static\', filename=\'proctorx-ui.js\') }}}}"></script>\n</head>')
    
    if 'proctorx-fab' not in content and 'dashboard' in file:
        content = content.replace('</body>', f'{fab_html}\n</body>')
        
    # Replace buttons to have wobbly and loading
    content = content.replace('class="btn-start"', 'class="btn-start proctorx-wobbly"')
    content = content.replace('class="btn-danger"', 'class="btn-danger proctorx-wobbly"')
    content = content.replace('class="primary-btn"', 'class="primary-btn proctorx-wobbly proctorx-btn-loading"')
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("Dashboards updated.")
