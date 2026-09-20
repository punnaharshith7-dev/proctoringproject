import re

with open('static/proctorx-ui.js', 'r', encoding='utf-8') as f:
    js = f.read()

new_toggle = '''const toggleHtml = <label class="dm-01__toggle-label" id="theme-toggle" aria-label="Toggle dark mode">
    <div class="dm-01__track">
    <div class="dm-01__knob">
        <span class="dm-01__knob-icon dm-01__knob-icon--sun">☀</span>
        <span class="dm-01__knob-icon dm-01__knob-icon--moon">☽</span>
    </div>
    </div>
</label>;'''

# Replace anything from const toggleHtml = to </div>; or </label>;
js = re.sub(r'const toggleHtml = [\s\S]*?(?:</div>;|</label>;?)', new_toggle, js)

with open('static/proctorx-ui.js', 'w', encoding='utf-8') as f:
    f.write(js)
print("Done")
