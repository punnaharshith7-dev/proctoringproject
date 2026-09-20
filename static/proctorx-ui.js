// Shared UI behavior for every ProctorX page.
(() => {
    const THEME_KEY = 'portal-theme';

    function preferredTheme() {
        return localStorage.getItem(THEME_KEY) ||
            (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    }

    function setTheme(theme) {
        document.documentElement.dataset.theme = theme;
        localStorage.setItem(THEME_KEY, theme);
        document.querySelectorAll('[data-theme-label]').forEach((label) => {
            label.textContent = theme === 'dark' ? 'Light mode' : 'Dark mode';
        });
    }

    function toggleTheme() {
        setTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark');
    }

    document.addEventListener('DOMContentLoaded', () => {
        setTheme(preferredTheme());

        // Pages with a built-in button keep their own layout. Add one only when absent.
        if (!document.querySelector('.theme-toggle, #theme-toggle')) {
            const toggle = document.createElement('button');
            toggle.type = 'button';
            toggle.id = 'theme-toggle';
            toggle.className = 'dm-01__toggle-label';
            toggle.setAttribute('aria-label', 'Switch colour theme');
            toggle.innerHTML = '<span class="dm-01__track" aria-hidden="true"><span class="dm-01__knob"><span class="dm-01__knob-icon dm-01__knob-icon--sun">☀</span><span class="dm-01__knob-icon dm-01__knob-icon--moon">☽</span></span></span><span class="dm-01__toggle-copy" data-theme-label></span>';
            toggle.addEventListener('click', toggleTheme);

            const sidebarActions = document.querySelector('#side-nav .side-bottom');
            const authAside = document.querySelector('.auth-aside');
            if (sidebarActions) sidebarActions.prepend(toggle);
            else if (authAside) authAside.appendChild(toggle);
            else document.body.appendChild(toggle);
        }

        document.querySelectorAll('form').forEach((form) => {
            form.addEventListener('submit', (event) => {
                const submitButton = form.querySelector('.proctorx-btn-loading[type="submit"]');
                if (!submitButton) return;
                if (submitButton.dataset.state === 'pending') {
                    event.preventDefault();
                    return;
                }
                submitButton.dataset.state = 'pending';
                submitButton.setAttribute('aria-busy', 'true');
            });
        });

        document.querySelectorAll('.proctorx-wobbly').forEach((button) => {
            if (button.dataset.wobblyReady === 'true') return;
            button.dataset.wobblyReady = 'true';
            const text = document.createElement('span');
            text.className = 'proctorx-wobbly-text';
            while (button.firstChild) text.appendChild(button.firstChild);
            button.appendChild(text);
            if (button.matches('.proctorx-btn-loading')) {
                const bar = document.createElement('span');
                bar.className = 'loading-bar';
                button.appendChild(bar);
            }
        });
    });

    // Existing inline controls call these functions.
    window.toggleTheme = toggleTheme;
    window.applyTheme = setTheme;
})();
