import os

files = [
    'templates/admin_dashboard_stats.html', 
    'templates/student_dashboard_theme.html', 
    'templates/student_profile.html'
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace('class="btn-clear"', 'class="btn-clear proctorx-btn-loading"')
    content = content.replace('class="btn-primary"', 'class="btn-primary proctorx-btn-loading"')
    content = content.replace('class="btn primary"', 'class="btn primary proctorx-btn-loading"')
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("Dashboards submit updated.")
