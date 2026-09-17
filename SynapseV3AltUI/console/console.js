/**
 * console.js
 * Console window controller:
 *   - Window minimization / maximization / close controls
 *   - Live log receiver from IPC (console:message)
 *   - Search filtering
 *   - Copy logs to clipboard
 *   - Clear logs
 *   - Autoscroll toggle
 *   - Dynamic theme loading synchronization
 */

(function () {
    const logs = [];
    let autoscroll = true;
    let searchQuery = '';

    const contentsEl = document.getElementById('console-contents');
    const searchInput = document.getElementById('console-search-input');
    const autoscrollToggle = document.getElementById('console-autoscroll-toggle');
    const copyBtn = document.getElementById('btn-console-copy');
    const clearBtn = document.getElementById('btn-console-clear');

    function formatTime(d = new Date()) {
        return d.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true,
        });
    }

    function normalizeLevel(level) {
        const l = String(level || 'print').toLowerCase();
        if (l === 'warn') return 'warning';
        if (l === 'err') return 'error';
        if (l === 'log' || l === 'output') return 'print';
        return l;
    }

    // ── Window Controls ───────────────────────────────────────────────────────
    const maxBtn = document.getElementById('ban_control_maximize');
    const restoreBtn = document.getElementById('ban_control_restore');

    function updateMaxState() {
        const isMax = window.hwAPI?.isMaximized?.();
        if (isMax) {
            if (maxBtn) maxBtn.style.display = 'none';
            if (restoreBtn) restoreBtn.style.display = 'flex';
        } else {
            if (maxBtn) maxBtn.style.display = 'flex';
            if (restoreBtn) restoreBtn.style.display = 'none';
        }
    }

    document.getElementById('ban_control_minimize')?.addEventListener('click', () => {
        window.hwAPI?.minimize();
    });

    maxBtn?.addEventListener('click', () => {
        window.hwAPI?.maximize();
        setTimeout(updateMaxState, 60);
    });

    restoreBtn?.addEventListener('click', () => {
        window.hwAPI?.maximize();
        setTimeout(updateMaxState, 60);
    });

    document.getElementById('ban_control_close')?.addEventListener('click', () => {
        window.hwAPI?.close();
    });

    const LEVEL_ICONS = {
        info: 'bx:info-circle',
        information: 'bx:info-circle',
        warning: 'bx:alert-triangle',
        warn: 'bx:alert-triangle',
        error: 'bx:alert-circle',
        print: null
    };

    const LEVEL_COLORS = {
        info: '#38bdf8',
        information: '#38bdf8',
        warning: '#fbbf24',
        warn: '#fbbf24',
        error: '#f87171',
        print: 'inherit'
    };

    function createLineElement(log) {
        const line = document.createElement('div');
        const level = log.level || 'print';
        line.className = `console-line level-${level}`;

        const timeSpan = document.createElement('span');
        timeSpan.className = 'timestamp';
        timeSpan.textContent = `[${log.time || formatTime()}]`;
        line.appendChild(timeSpan);

        const iconName = LEVEL_ICONS[level];
        if (iconName) {
            const iconEl = document.createElement('iconify-icon');
            iconEl.setAttribute('icon', iconName);
            iconEl.className = 'console-msg-icon';
            iconEl.style.color = LEVEL_COLORS[level] || 'inherit';
            line.appendChild(iconEl);
        }

        const textSpan = document.createElement('span');
        textSpan.className = 'text';
        textSpan.textContent = log.text || '';
        line.appendChild(textSpan);

        return line;
    }

    // ── Log Rendering ─────────────────────────────────────────────────────────
    function renderLogs() {
        if (!contentsEl) return;
        contentsEl.innerHTML = '';

        const q = searchQuery.trim().toLowerCase();
        const filtered = q
            ? logs.filter(l => (l.text || '').toLowerCase().includes(q) || (l.time || '').toLowerCase().includes(q))
            : logs;

        filtered.forEach(log => {
            contentsEl.appendChild(createLineElement(log));
        });

        if (autoscroll) {
            contentsEl.scrollTop = contentsEl.scrollHeight;
        }
    }

    function appendLog(log) {
        if (!log || typeof log !== 'object') {
            log = { level: 'print', text: String(log), time: formatTime() };
        }
        if (!log.time) log.time = formatTime();
        log.level = normalizeLevel(log.level);
        logs.push(log);

        // Enforce maximum log preservation limit from setting
        const maxPreserve = parseInt(localStorage.getItem('synapse_setting_max_log_count') || '720', 10);
        if (logs.length > maxPreserve) {
            logs.splice(0, logs.length - maxPreserve);
            renderLogs();
            return;
        }

        const q = searchQuery.trim().toLowerCase();
        if (!q || (log.text || '').toLowerCase().includes(q) || (log.time || '').toLowerCase().includes(q)) {
            contentsEl.appendChild(createLineElement(log));

            if (autoscroll) {
                contentsEl.scrollTop = contentsEl.scrollHeight;
            }
        }
    }

    // ── Actions ───────────────────────────────────────────────────────────────
    if (copyBtn) {
        copyBtn.addEventListener('click', async () => {
            const q = searchQuery.trim().toLowerCase();
            const filtered = q
                ? logs.filter(l => (l.text || '').toLowerCase().includes(q))
                : logs;
            const textToCopy = filtered.map(l => `[${l.time}] ${l.text}`).join('\n');
            if (!textToCopy) return;

            try {
                await navigator.clipboard.writeText(textToCopy);
                const originalHtml = copyBtn.innerHTML;
                copyBtn.innerHTML = '<iconify-icon icon="fluent:checkmark-20-filled" class="flex items-center justify-center"></iconify-icon> Copied!';
                setTimeout(() => { copyBtn.innerHTML = originalHtml; }, 1500);
            } catch (_) {}
        });
    }

    if (clearBtn) {
        clearBtn.addEventListener('click', () => {
            window.hwAPI.clearConsole();
            logs.length = 0;
            renderLogs();
        });
    }

    /*
    const testBtn = document.getElementById('btn-console-test');
    if (testBtn) {
        testBtn.addEventListener('click', () => {
            const time = formatTime();
            appendLog({ level: 'print', text: 'Hello from Lua print() output [Print test]', time });
            appendLog({ level: 'info', text: 'Script initialized successfully [Info test]', time });
            appendLog({ level: 'warning', text: 'Deprecated function call detected at line 14 [Warning test]', time });
            appendLog({ level: 'error', text: 'Workspace script runtime error: attempt to index nil with \'Character\' [Error test]', time });
        });
    }

    window.testConsole = function (level = 'info', text = 'Sample console message') {
        appendLog({ level, text, time: formatTime() });
    };
    */

    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            searchQuery = e.target.value;
            renderLogs();
        });
        searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                searchInput.value = '';
                searchQuery = '';
                renderLogs();
                searchInput.blur();
            }
        });
    }

    function setAutoscroll(enabled) {
        autoscroll = !!enabled;
        if (autoscrollToggle) {
            const icon = autoscrollToggle.querySelector('.icon');
            if (autoscroll) {
                autoscrollToggle.classList.add('on');
                if (icon) {
                    icon.classList.remove('translate-x-1');
                    icon.classList.add('translate-x-5');
                }
            } else {
                autoscrollToggle.classList.remove('on');
                if (icon) {
                    icon.classList.remove('translate-x-5');
                    icon.classList.add('translate-x-1');
                }
            }
        }
    }

    if (autoscrollToggle) {
        autoscrollToggle.addEventListener('click', () => {
            setAutoscroll(!autoscroll);
        });
    }

    document.getElementById('label-autoscroll')?.addEventListener('click', () => {
        setAutoscroll(!autoscroll);
    });

    // Native and bundled descriptors use inline CSS with root-relative asset URLs.
    async function syncTheme() {
        const id = await window.hwAPI.getSetting('theme', 'hollywood-dark');
        const meta = await window.hwAPI.loadTheme(id);
        const link = document.getElementById('theme-style');
        if (link) { link.disabled = true; link.removeAttribute('href'); }
        let style = document.getElementById('theme-custom-style');
        if (!style) { style = document.createElement('style'); style.id = 'theme-custom-style'; document.head.append(style); }
        style.textContent = (meta?.cssContent || '').replace(/url\(['"]?((?:assets|themes)\/[^)'"]+)['"]?\)/g, (_, url) => `url('../${url}')`);
    }
    syncTheme();
    window.hwAPI.onThemesChanged(syncTheme);
    window.hwAPI.onSettingsChanged(syncTheme);
    window.hwAPI.onWindowState(updateMaxState);
    document.querySelector('.hw-titlebar')?.addEventListener('pointerdown', event => {
        if (event.button === 0 && !event.target.closest('#controls')) window.hwAPI.startWindowDrag();
    });

    // ── Incoming Logs IPC Listener ────────────────────────────────────────────
    window.hwAPI?.onConsoleMessage?.((msg) => {
        appendLog(msg);
    });

    // A host may deliver the backlog as one array instead of replaying events.
    window.hwAPI?.onConsoleSnapshot?.((messages) => {
        logs.length = 0;
        (Array.isArray(messages) ? messages : []).forEach(appendLog);
        renderLogs();
    });

    // Flush any logs that were dispatched before opening
    window.hwAPI?.flushConsoleLogs?.();
})();
