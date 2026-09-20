import re
import codecs

with codecs.open(r'C:\Users\punna\.gemini\antigravity\brain\526a60a0-79b6-41a6-9835-f7343220acf4\.system_generated\steps\157\content.md', 'r', 'utf-8') as f:
    content = f.read()

ghost = re.search(r'class="svgb-01__ghost" d="([^"]+)"', content).group(1)
p1 = re.search(r'class="svgb-01__p1" d="([^"]+)"', content).group(1)
p2 = re.search(r'class="svgb-01__p2" d="([^"]+)"', content).group(1)

js_code = f'''
const WOBBLY_GHOST = "{{ghost}}";
const WOBBLY_P1 = "{{p1}}";
const WOBBLY_P2 = "{{p2}}";

document.addEventListener('DOMContentLoaded', () => {{{{
    const wobblyBtns = document.querySelectorAll('.proctorx-wobbly');
    wobblyBtns.forEach(btn => {{{{
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('class', 'wobbly-svg');
        svg.setAttribute('viewBox', '0 0 560 128');
        svg.setAttribute('aria-hidden', 'true');
        svg.setAttribute('preserveAspectRatio', 'none');
        
        const pathGhost = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        pathGhost.setAttribute('class', 'wobbly-ghost');
        pathGhost.setAttribute('d', WOBBLY_GHOST);
        
        const pathP1 = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        pathP1.setAttribute('class', 'wobbly-p1');
        pathP1.setAttribute('d', WOBBLY_P1);
        
        const pathP2 = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        pathP2.setAttribute('class', 'wobbly-p2');
        pathP2.setAttribute('d', WOBBLY_P2);
        
        svg.appendChild(pathGhost);
        svg.appendChild(pathP1);
        svg.appendChild(pathP2);
        
        const innerSpan = document.createElement('span');
        innerSpan.className = 'proctorx-wobbly-text';
        while (btn.firstChild) {{{{
            innerSpan.appendChild(btn.firstChild);
        }}}}
        
        btn.appendChild(svg);
        btn.appendChild(innerSpan);
        
        if (btn.type === 'submit' || btn.classList.contains('proctorx-btn-loading')) {{{{
            const loadingBar = document.createElement('span');
            loadingBar.className = 'loading-bar';
            btn.appendChild(loadingBar);
        }}}}
    }}}});
    
    // Inject Theme Toggle
    const toggleHtml = \<div class="proctorx-theme-toggle" id="theme-toggle" role="button" tabindex="0" aria-label="Toggle theme">
        <svg class="icon-sun" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.25a.75.75 0 0 1 .75.75v2.25a.75.75 0 0 1-1.5 0V3a.75.75 0 0 1 .75-.75ZM7.5 12a4.5 4.5 0 1 1 9 0 4.5 4.5 0 0 1-9 0ZM18.884 5.116a.75.75 0 0 0-1.06-1.06l-1.591 1.59a.75.75 0 0 0 1.06 1.061l1.591-1.59ZM21.75 12a.75.75 0 0 1-.75.75h-2.25a.75.75 0 0 1 0-1.5H21a.75.75 0 0 1 .75.75ZM17.823 18.884a.75.75 0 0 0 1.06-1.06l-1.59-1.591a.75.75 0 1 0-1.061 1.06l1.59 1.591ZM12 18.75a.75.75 0 0 1 .75.75V21a.75.75 0 0 1-1.5 0v-1.5a.75.75 0 0 1 .75-.75ZM5.116 18.884a.75.75 0 0 0 1.06 1.06l1.591-1.59a.75.75 0 1 0-1.06-1.061l-1.591 1.59ZM2.25 12a.75.75 0 0 1 .75-.75h2.25a.75.75 0 0 1 0 1.5H3a.75.75 0 0 1-.75-.75ZM6.177 5.116a.75.75 0 0 0-1.06 1.06l1.59 1.591a.75.75 0 1 0 1.061-1.06l-1.59-1.591Z"/></svg>
        <svg class="icon-moon" viewBox="0 0 24 24" aria-hidden="true"><path d="M9.528 1.718a.75.75 0 0 1 .162.819A8.97 8.97 0 0 0 9 6a9 9 0 0 0 9 9 8.97 8.97 0 0 0 3.463-.69.75.75 0 0 1 .981.98 10.503 10.503 0 0 1-9.694 6.46c-5.799 0-10.5-4.701-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 0 1 .818.162Z"/></svg>
    </div>\;
    
    const div = document.createElement('div');
    div.innerHTML = toggleHtml;
    const toggleEl = div.firstElementChild;
    toggleEl.style.position = 'absolute';
    toggleEl.style.top = '20px';
    toggleEl.style.right = '20px';
    toggleEl.style.zIndex = '9999';
    
    const authAside = document.querySelector('.auth-aside');
    const sideNav = document.querySelector('#side-nav');
    
    if (authAside) {{{{
        authAside.appendChild(toggleEl);
    }}}} else if (sideNav) {{{{
        sideNav.appendChild(toggleEl);
    }}}} else {{{{
        document.body.appendChild(toggleEl);
    }}}}
    
    const themeToggle = document.getElementById('theme-toggle');
    const root = document.documentElement;
    if (themeToggle) {{{{
        themeToggle.addEventListener('click', () => {{{{
            if (root.getAttribute('data-theme') === 'light') {{{{
                root.removeAttribute('data-theme');
                localStorage.setItem('theme', 'dark');
            }}}} else {{{{
                root.setAttribute('data-theme', 'light');
                localStorage.setItem('theme', 'light');
            }}}}
        }}}});
    }}}}
}}}});
'''

with codecs.open('static/proctorx-ui.js', 'a', 'utf-8') as f:
    f.write(js_code)

print("success")
