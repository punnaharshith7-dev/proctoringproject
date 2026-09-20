const fs = require('fs');
let js = fs.readFileSync('static/proctorx-ui.js', 'utf8');

const new_toggle_html = 'const toggleHtml = <label class="dm-01__toggle-label" id="theme-toggle" aria-label="Toggle dark mode">\\n    <div class="dm-01__track">\\n    <div class="dm-01__knob">\\n        <span class="dm-01__knob-icon dm-01__knob-icon--sun">☀</span>\\n        <span class="dm-01__knob-icon dm-01__knob-icon--moon">☽</span>\\n    </div>\\n    </div>\\n</label>;';

// Replace the old HTML block
js = js.replace(/const toggleHtml = [\s\S]*?<\/div>;/, new_toggle_html);
js = js.replace(/const toggleHtml = <label[\s\S]*?<\/label>;/, new_toggle_html);

// Remove toggleEl.style.* lines
js = js.replace(/toggleEl\.style\..*?;/g, '');

fs.writeFileSync('static/proctorx-ui.js', js, 'utf8');

let css = fs.readFileSync('static/proctorx-ui.css', 'utf8');
// Fix the CSS emojis that became ?
css = css.replace(/\?/g, ''); // just in case
fs.writeFileSync('static/proctorx-ui.css', css, 'utf8');
console.log('done');
