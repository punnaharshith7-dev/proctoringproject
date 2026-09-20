import re

with open('static/proctorx-ui.js', 'r', encoding='utf-8') as f:
    js = f.read()

new_toggle = '''const toggleHtml = `<label class="dm-01__toggle-label" id="theme-toggle" aria-label="Toggle dark mode">
    <div class="dm-01__track">
    <div class="dm-01__knob">
        <span class="dm-01__knob-icon dm-01__knob-icon--sun">\u2600</span>
        <span class="dm-01__knob-icon dm-01__knob-icon--moon">\u263d</span>
    </div>
    </div>
</label>`;'''

parts = js.split('const toggleHtml = `')
before = parts[0]
after = parts[1].split('</label>`;', 1)[1]

js = before + new_toggle + after

with open('static/proctorx-ui.js', 'w', encoding='utf-8') as f:
    f.write(js)
print("Done")
