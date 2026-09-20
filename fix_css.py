import re

with open('static/proctorx-ui.css', 'r', encoding='utf-8') as f:
    css = f.read()

new_css = '''
/* 1. Dark/Light Mode Toggle (dm-01 exact from user) */
.dm-01__toggle-label {
  display: flex;
  align-items: center;
  cursor: pointer;
  user-select: none;
  position: fixed;
  top: 40px;
  right: 40px;
  z-index: 9999;
}

.dm-01__track {
  --dur: 0.55s;
  --ease: cubic-bezier(0.34,1.56,0.64,1);
  width: 64px;
  height: 34px;
  border-radius: 17px;
  background: #f8f6ff;
  border: 1.5px solid #e0daff;
  position: relative;
  transition:
    background var(--dur) ease,
    border-color var(--dur) ease,
    box-shadow var(--dur) ease;
}

[data-theme="dark"] .dm-01__track {
  background: linear-gradient(135deg, #7c6af7, #e91e8c);
  border-color: transparent;
  box-shadow:
    0 0 16px rgba(157,142,255,0.3),
    0 2px 8px rgba(0,0,0,0.3);
}

.dm-01__knob {
  position: absolute;
  top: 3.5px;
  left: 3.5px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #fff;
  box-shadow: 0 2px 6px rgba(0,0,0,0.2);
  transition:
    transform var(--dur) var(--ease),
    box-shadow var(--dur) ease;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  color: #1a1530;
}

[data-theme="dark"] .dm-01__knob {
  transform: translateX(30px);
  box-shadow: 0 2px 10px rgba(0,0,0,0.4);
}

.dm-01__knob-icon {
  transition:
    opacity var(--dur) ease,
    transform var(--dur) ease;
  position: absolute;
  line-height: 1;
}

.dm-01__knob-icon--sun {
  opacity: 1;
  transform: scale(1) rotate(0deg);
}

.dm-01__knob-icon--moon {
  opacity: 0;
  transform: scale(0.4) rotate(-90deg);
}

[data-theme="dark"] .dm-01__knob-icon--sun {
  opacity: 0;
  transform: scale(0.4) rotate(90deg);
}

[data-theme="dark"] .dm-01__knob-icon--moon {
  opacity: 1;
  transform: scale(1) rotate(0deg);
}

'''

parts = css.split('/* 2. Loading Buttons')
css = '/* --- PROCTORX UI OVERHAUL --- */\n' + new_css + '\n/* 2. Loading Buttons' + parts[1]

with open('static/proctorx-ui.css', 'w', encoding='utf-8') as f:
    f.write(css)

print("CSS updated")
