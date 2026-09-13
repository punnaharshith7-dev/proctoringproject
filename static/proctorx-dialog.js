(() => {
    const iconByType = { success: 'OK', info: 'i', warning: '!', danger: '!' };

    function ensureDialog() {
        let layer = document.getElementById('proctorx-dialog-layer');
        if (layer) return layer;
        layer = document.createElement('div');
        layer.id = 'proctorx-dialog-layer';
        layer.className = 'proctorx-dialog-layer';
        layer.innerHTML = '<section class="proctorx-dialog" role="dialog" aria-modal="true" aria-labelledby="proctorx-dialog-title"><header class="proctorx-dialog-head"><div class="proctorx-dialog-icon" id="proctorx-dialog-icon"></div><div><div class="proctorx-dialog-title" id="proctorx-dialog-title"></div><div class="proctorx-dialog-kicker">ProctorX system message</div></div></header><div class="proctorx-dialog-body" id="proctorx-dialog-body"></div><footer class="proctorx-dialog-actions" id="proctorx-dialog-actions"></footer></section>';
        document.body.appendChild(layer);
        return layer;
    }

    function showDialog(options = {}) {
        const config = typeof options === 'string' ? { message: options } : options;
        const layer = ensureDialog();
        const type = config.type || 'info';
        const title = config.title || (type === 'danger' ? 'Action needs attention' : type === 'warning' ? 'Assessment integrity notice' : type === 'success' ? 'Update complete' : 'ProctorX notification');
        const icon = layer.querySelector('#proctorx-dialog-icon');
        const actions = layer.querySelector('#proctorx-dialog-actions');
        icon.textContent = iconByType[type] || 'i';
        icon.className = `proctorx-dialog-icon ${type === 'warning' ? 'warn' : type === 'danger' ? 'danger' : ''}`;
        layer.querySelector('#proctorx-dialog-title').textContent = title;
        layer.querySelector('#proctorx-dialog-body').textContent = config.message || '';
        actions.innerHTML = '';

        return new Promise((resolve) => {
            let settled = false;
            const onKeyDown = (event) => {
                if (event.key === 'Escape') close(config.confirm ? false : true);
            };
            const close = (value) => {
                if (settled) return;
                settled = true;
                document.removeEventListener('keydown', onKeyDown);
                layer.classList.remove('is-open');
                window.setTimeout(() => { actions.innerHTML = ''; resolve(value); }, 220);
            };
            const addButton = (label, className, value) => {
                const button = document.createElement('button');
                button.type = 'button';
                button.className = `proctorx-dialog-button ${className}`;
                button.textContent = label;
                button.addEventListener('click', () => close(value));
                actions.appendChild(button);
                return button;
            };
            const cancel = config.confirm ? addButton(config.cancelText || 'Cancel', '', false) : null;
            const confirm = addButton(config.confirmText || (config.confirm ? 'Continue' : 'Close'), config.confirm ? (type === 'danger' ? 'danger' : 'primary') : 'primary', true);
            layer.onclick = (event) => { if (event.target === layer && !config.confirm) close(true); };
            document.addEventListener('keydown', onKeyDown);
            layer.classList.add('is-open');
            (cancel || confirm).focus();
        });
    }

    window.proctorxAlert = (message, options = {}) => showDialog({ ...options, message, confirm: false });
    window.proctorxConfirm = (message, options = {}) => showDialog({ ...options, message, confirm: true });
})();
