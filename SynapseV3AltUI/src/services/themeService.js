/**
 * themeService.js
 * Theme management, CSS swapping, metric variable injection,
 * and Monaco Editor token color definitions.
 */

export const THEME_IDS = [
    'coolkid', 'elysian-fields', 'freeman', 'hollywood-classic', 'hollywood-dark',
    'hollywood-glass', 'hollywood-light', 'hollywood-novo', 'kyoto', 'neon',
    'seven', 'unikoi',
];

const DEFAULT_ICONS = {
    '#execute-button iconify-icon': 'fluent:play-20-filled',
    '#clear-button iconify-icon': 'fluent:eraser-20-filled',
    '#openf-button iconify-icon': 'fluent:document-arrow-up-20-filled',
    '#executef-button iconify-icon': 'fluent:settings-20-filled',
    '#savef-button iconify-icon': 'fluent:save-20-filled',

    '#nav-editor iconify-icon': 'fluent:window-console-20-filled',
    '#nav-settings iconify-icon': 'fluent:settings-20-filled',
    '#nav-themes iconify-icon': 'fluent:paint-brush-20-filled',
    '#nav-plugins iconify-icon': 'fluent:puzzle-piece-20-filled',

    '.connection-toggle iconify-icon:not(.absolute)': 'fluent:plug-disconnected-20-filled',
    '#console-icon iconify-icon': 'fluent:pulse-square-20-regular',
    '#documentation-icon iconify-icon': 'fluent:search-square-20-regular',
    '#target-menu iconify-icon': 'fluent:flash-20-filled'
};

const ICON_MAPPINGS = [
    { selector: '#execute-button iconify-icon', keys: ['btn-execute', 'play'] },
    { selector: '#clear-button iconify-icon', keys: ['btn-clear'] },
    { selector: '#openf-button iconify-icon', keys: ['btn-file-open', 'folder-open'] },
    { selector: '#executef-button iconify-icon', keys: ['btn-file-execute', 'settings'] },
    { selector: '#savef-button iconify-icon', keys: ['btn-file-save'] },

    { selector: '#nav-editor iconify-icon', keys: ['page-editor'] },
    { selector: '#nav-settings iconify-icon', keys: ['page-settings'] },
    { selector: '#nav-themes iconify-icon', keys: ['page-customization'] },
    { selector: '#nav-plugins iconify-icon', keys: ['page-powertools'] },

    { selector: '.connection-toggle iconify-icon:not(.absolute)', keys: ['connection-disabled'] },
    { selector: '#console-icon iconify-icon', keys: ['console'] },
    { selector: '#documentation-icon iconify-icon', keys: ['documentation', 'page-documentation'] }
];

export const HOLLYWOOD_DARK_RULES = [
    { token: 'keyword', foreground: 'EA4A5A' },
    { token: 'keyword.synapse', foreground: 'EA4A5A' },
    { token: 'type', foreground: 'EA4A5A' },
    { token: 'predefined', foreground: 'FFD866' },
    { token: 'entity.name.function', foreground: 'FFD866' },
    { token: 'function', foreground: 'FFD866' },
    { token: 'string', foreground: '79B8FF' },
    { token: 'number', foreground: 'B5CEA8' },
    { token: 'number.float', foreground: 'B5CEA8' },
    { token: 'number.hex', foreground: '5BB498' },
    { token: 'comment', foreground: '959DA5', fontStyle: 'italic' },
    { token: 'operator', foreground: 'DCDCDC' },
    { token: 'delimiter', foreground: 'DCDCDC' },
    { token: 'identifier', foreground: 'F6F8FA' }
];

export const FALLBACK_LUA_RULES = [
    { token: 'keyword', foreground: '569CD6' },
    { token: 'keyword.synapse', foreground: '569CD6' },
    { token: 'type', foreground: '569CD6' },
    { token: 'predefined', foreground: '569CD6' },
    { token: 'string', foreground: 'CE9178' },
    { token: 'string.escape', foreground: 'CE9178' },
    { token: 'comment', foreground: '608B4E', fontStyle: 'italic' },
    { token: 'operator', foreground: 'FFFF00' },
    { token: 'delimiter', foreground: 'FFFF00' },
    { token: 'delimiter.bracket', foreground: 'FFFF00' },
    { token: 'delimiter.array', foreground: 'FFFF00' },
    { token: 'delimiter.parenthesis', foreground: 'FFFF00' },
    { token: 'number', foreground: 'FFFFFF' },
    { token: 'number.float', foreground: 'FFFFFF' },
    { token: 'number.hex', foreground: 'FFFFFF' },
    { token: 'identifier', foreground: 'FFFFFF' },
    { token: 'entity.name.function', foreground: 'FFFFFF' },
    { token: 'function', foreground: 'FFFFFF' },
];

class ThemeService {
    constructor() {
        this.themeMetas = {};
        this.currentThemeId = localStorage.getItem('synapse_setting_theme') || 'hollywood-dark';
        this.currentIcons = {};
        this.listeners = new Set();
        this.init();
    }

    async init() {
        await this.refreshThemes();
        const saved = (await window.hwAPI?.getSetting?.('theme', 'hollywood-dark')) || this.currentThemeId;
        await this.loadTheme(saved);

        window.hwAPI?.onThemesChanged?.(async () => {
            await this.refreshThemes();
            this.notify();
        });
    }

    async refreshThemes() {
        try {
            const installed = await window.hwAPI?.listThemes?.();
            if (installed && Array.isArray(installed) && installed.length > 0) {
                installed.forEach(t => {
                    const data = {
                        ...t.meta,
                        ...t,
                        id: t.id,
                        folderName: t.folderName || t.id,
                        name: t.name,
                        icons: t.icons || (t.meta && t.meta.icons) || {},
                        editorTheme: t.editorTheme || (t.meta && t.meta.editorTheme) || null,
                        cssPath: t.cssPath,
                        cssAvailable: t.cssExists,
                        isCustom: t.isCustom
                    };
                    this.themeMetas[t.id] = data;
                    if (t.folderName && t.folderName !== t.id) {
                        this.themeMetas[t.folderName] = data;
                    }
                });
                return true;
            }
        } catch (_) {}

        // Fallback
        await Promise.all(THEME_IDS.map(async (id) => {
            const res = await window.hwAPI?.loadTheme?.(id);
            if (res && res.meta) {
                this.themeMetas[id] = { ...res.meta, ...res, id, name: res.name || res.meta.name, icons: res.icons || {}, editorTheme: res.editorTheme || null, cssPath: res.cssPath, cssAvailable: res.cssExists };
            } else {
                const formatted = id.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
                this.themeMetas[id] = { id, name: formatted, icons: {}, editorTheme: null, cssAvailable: false };
            }
        }));
        return false;
    }

    applyMetrics(meta) {
        const metrics = { 'ux-button-padding-v': 0.25, 'ux-button-padding-h': 0.6, 'ux-border-radius': 0.375, ...(meta?.metrics || {}) };
        const vars = [];
        for (const [key, def] of Object.entries(metrics)) {
            const value = def && typeof def === 'object' && 'default' in def ? def.default : def;
            if (value !== undefined && value !== null) {
                const cssValue = typeof value === 'number' ? `${value}rem` : String(value);
                if (/^[a-zA-Z0-9-]+$/.test(key) && /^[\d.%-]+(?:px|rem|em)?$/.test(cssValue)) vars.push(`--${key}: ${cssValue};`);
            }
        }
        // Stylesheets reference these custom properties with no fallback value;
        // always publish defaults so themes without a metrics block stay usable.
        let styleEl = document.getElementById('theme-metrics');
        if (!styleEl) {
            styleEl = document.createElement('style');
            styleEl.id = 'theme-metrics';
            document.head.appendChild(styleEl);
        }
        styleEl.textContent = `:root { ${vars.join(' ')} }`;
    }

    getThemeIcon(key, fallback) {
        if (this.currentIcons && this.currentIcons[key]) {
            return this.currentIcons[key];
        }
        const meta = this.themeMetas[this.currentThemeId];
        if (meta && meta.icons && meta.icons[key]) {
            return meta.icons[key];
        }
        return fallback;
    }

    applyIcons(icons = {}) {
        this.currentIcons = icons;
        ICON_MAPPINGS.forEach(({ selector, keys }) => {
            let iconToSet = null;
            for (const k of keys) {
                if (icons && icons[k]) {
                    iconToSet = icons[k];
                    break;
                }
            }
            if (!iconToSet) {
                iconToSet = DEFAULT_ICONS[selector];
            }
            if (iconToSet) {
                document.querySelectorAll(selector).forEach(el => {
                    try { el.icon = iconToSet; } catch (_) {}
                    el.setAttribute('icon', iconToSet);
                });
            }
        });
    }

    async loadTheme(themeId) {
        let meta = this.themeMetas[themeId] || Object.values(this.themeMetas).find(m => m.id === themeId || m.folderName === themeId);
        if (!meta || !meta.cssContent || meta.isCustom) {
            const res = await window.hwAPI?.loadTheme?.(themeId);
            if (res) {
                meta = {
                    ...res.meta,
                    ...res,
                    id: res.id,
                    name: res.name,
                    icons: res.icons || {},
                    editorTheme: res.editorTheme || null,
                    cssPath: res.cssPath,
                    cssContent: res.cssContent,
                    cssAvailable: res.cssExists,
                    isCustom: res.isCustom
                };
                this.themeMetas[res.id] = meta;
                this.themeMetas[themeId] = meta;
            }
        }
        if (!meta) return false;

        this.currentThemeId = meta.id;
        localStorage.setItem('synapse_setting_theme', meta.id);
        window.hwAPI?.setSetting?.('theme', meta.id);

        // Swap stylesheet link and custom inline style
        let customStyleEl = document.getElementById('theme-custom-style');
        let link = document.getElementById('theme-style');
        if (!link) {
            link = document.createElement('link');
            link.id = 'theme-style';
            link.rel = 'stylesheet';
            document.head.appendChild(link);
        }

        if (meta.cssContent) {
            if (!customStyleEl) {
                customStyleEl = document.createElement('style');
                customStyleEl.id = 'theme-custom-style';
                document.head.appendChild(customStyleEl);
            }
            customStyleEl.textContent = meta.cssContent;
            // Always move custom style element to the very end of <head> for ultimate cascade priority
            document.head.appendChild(customStyleEl);

            // Completely disable and remove href from prebuilt link so stale prebuilt stylesheets never conflict
            if (link) {
                link.disabled = true;
                link.removeAttribute('href');
            }
        } else {
            if (customStyleEl) {
                customStyleEl.textContent = '';
            }
            if (link) {
                link.disabled = false;
                link.href = `assets/styles/prebuilt/_prebuilt-${meta.id}.css`;
                document.head.appendChild(link);
            }
        }

        // Apply metrics
        this.applyMetrics(meta);

        // Apply icons
        this.applyIcons(meta.icons || {});

        // Patch Seven theme window classes
        const appEl = document.getElementById('application');
        if (appEl) {
            if (meta.id === 'seven') {
                appEl.classList.add('window', 'glass', 'is-bright');
            } else {
                appEl.classList.remove('window', 'glass', 'is-bright');
            }
        }

        // Apply Monaco editor theme if Monaco is loaded
        this.applyEditorTheme(meta.id);

        this.notify();
        document.dispatchEvent(new CustomEvent('theme:changed', { detail: { id: meta.id, name: meta.name } }));
        return true;
    }

    async applyEditorTheme(themeId, monacoInstance = null) {
        const mon = monacoInstance || (typeof window !== 'undefined' && window.monaco ? window.monaco : (typeof monaco !== 'undefined' ? monaco : null));
        if (!mon || !mon.editor) return;

        if (themeId === 'coolkid') {
            mon.editor.setTheme('hc-black');
            return;
        }
        const currentMeta = this.themeMetas[themeId] || Object.values(this.themeMetas).find(m => m.id === themeId || m.folderName === themeId);
        if (themeId === 'seven' || themeId === 'hollywood-light' || currentMeta?.editor === 'synapse-light' || currentMeta?.editor === 'hollywood-light' || currentMeta?.editor === 'vs') {
            mon.editor.setTheme('vs');
            return;
        }
        if (themeId === 'hollywood-dark') {
            mon.editor.defineTheme('hw-hollywood-dark', {
                base: 'vs-dark',
                inherit: true,
                rules: HOLLYWOOD_DARK_RULES,
                colors: {
                    'editor.background': '#000000',
                    'editorGutter.background': '#000000',
                    'editor.foreground': '#F6F8FA',
                    'editorCursor.foreground': '#F6F8FA',
                    'editor.selectionBackground': '#403e41',
                    'editor.lineHighlightBackground': '#19181a'
                }
            });
            mon.editor.setTheme('hw-hollywood-dark');
            return;
        }
        if (themeId === 'hollywood-glass') {
            mon.editor.defineTheme('hw-hollywood-glass', {
                base: 'vs-dark',
                inherit: true,
                rules: HOLLYWOOD_DARK_RULES,
                colors: {
                    'editor.background': '#00000000',
                    'editorGutter.background': '#00000000',
                    'editor.foreground': '#F6F8FA',
                    'editorCursor.foreground': '#F6F8FA',
                    'editor.selectionBackground': '#403e41',
                    'editor.lineHighlightBackground': '#19181a44'
                }
            });
            mon.editor.setTheme('hw-hollywood-glass');
            return;
        }

        try {
            const meta = this.themeMetas[themeId] || Object.values(this.themeMetas).find(m => m.id === themeId || m.folderName === themeId);
            let def = meta?.editorTheme || null;

            if (!def && window.hwAPI?.loadTheme) {
                const res = await window.hwAPI.loadTheme(themeId);
                if (res && res.editorTheme) def = res.editorTheme;
            }

            if (!def) {
                const folder = meta?.folderName || themeId;
                const candidates = [
                    meta?.themeDir ? `${meta.themeDir}/editor.json` : null,
                    `themes/${folder}/editor.json`,
                    `themes/${themeId}/editor.json`,
                    `assets/styles/default-themes/${folder}/editor.json`,
                    `assets/styles/default-themes/${themeId}/editor.json`
                ].filter(Boolean);

                for (const path of candidates) {
                    try {
                        const response = await fetch(path);
                        if (response.ok) {
                            def = await response.json();
                            break;
                        }
                    } catch (_) {}
                }
            }

            if (!def) {
                const themeName = 'hw-' + (meta?.id || themeId);
                mon.editor.defineTheme(themeName, {
                    base: 'vs-dark',
                    inherit: true,
                    rules: FALLBACK_LUA_RULES,
                    colors: {
                        'editor.background': '#000000',
                        'editorGutter.background': '#000000',
                        'editor.foreground': '#FFFFFF',
                        'editorCursor.foreground': '#FFFFFF',
                        'editor.selectionBackground': '#264F78',
                        'editor.lineHighlightBackground': '#19181a'
                    }
                });
                mon.editor.setTheme(themeName);
                return;
            }

            const stripHash = (hex) => (hex && typeof hex === 'string' && hex.startsWith('#') ? hex.slice(1) : hex);
            let rules = [];
            let colors = def.colors || {};

            // Shorthand editor schema support
            if (def.bg || def.fg || def.keyword) {
                if (def.bg) {
                    colors['editor.background'] = def.bg;
                    colors['editorGutter.background'] = def.bg;
                }
                if (def.fg) colors['editor.foreground'] = def.fg;
                if (def.selection) colors['editor.selectionBackground'] = def.selection;
                if (def.lineHighlight) colors['editor.lineHighlightBackground'] = def.lineHighlight;
                if (def.cursor) colors['editorCursor.foreground'] = def.cursor;
                if (def.lineNumber) colors['editorLineNumber.foreground'] = def.lineNumber;

                if (def.comment) rules.push({ token: 'comment', foreground: stripHash(def.comment), fontStyle: 'italic' });
                if (def.string) rules.push({ token: 'string', foreground: stripHash(def.string) });
                if (def.keyword) rules.push({ token: 'keyword', foreground: stripHash(def.keyword) }, { token: 'keyword.synapse', foreground: stripHash(def.type || def.keyword) });
                if (def.number) rules.push({ token: 'number', foreground: stripHash(def.number) }, { token: 'constant', foreground: stripHash(def.number) });
                if (def.type) rules.push({ token: 'type', foreground: stripHash(def.type) }, { token: 'keyword.synapse', foreground: stripHash(def.type) });
                if (def.function) rules.push({ token: 'predefined', foreground: stripHash(def.function) }, { token: 'function', foreground: stripHash(def.function) }, { token: 'entity.name.function', foreground: stripHash(def.function) });
                if (def.operator) rules.push({ token: 'operator', foreground: stripHash(def.operator) }, { token: 'delimiter', foreground: stripHash(def.operator) });
                if (def.variable) rules.push({ token: 'variable', foreground: stripHash(def.variable) }, { token: 'identifier', foreground: stripHash(def.variable) });
            }

            // VS Code tokenColors support
            if (def.tokenColors && Array.isArray(def.tokenColors)) {
                def.tokenColors.forEach(tc => {
                    if (!tc.settings || !tc.settings.foreground) return;
                    const fg = stripHash(tc.settings.foreground);
                    const bg = stripHash(tc.settings.background);
                    const fontStyle = tc.settings.fontStyle;
                    const scopes = Array.isArray(tc.scope) ? tc.scope : (typeof tc.scope === 'string' ? tc.scope.split(/,\s*/) : []);

                    scopes.forEach(rawScope => {
                        const scope = rawScope.trim();
                        if (!scope) return;
                        rules.push({ token: scope, foreground: fg, background: bg, fontStyle });
                        if (scope.startsWith('keyword') || scope.startsWith('storage')) rules.push({ token: 'keyword', foreground: fg });
                        if (scope.startsWith('entity.name.type') || scope.startsWith('support.type')) {
                            rules.push({ token: 'type', foreground: fg });
                            rules.push({ token: 'keyword.synapse', foreground: fg });
                        }
                        if (scope.startsWith('entity.name.function') || scope.startsWith('support.function')) rules.push({ token: 'predefined', foreground: fg });
                        if (scope.startsWith('string')) rules.push({ token: 'string', foreground: fg });
                        if (scope.startsWith('constant.numeric')) rules.push({ token: 'number', foreground: fg });
                        if (scope.startsWith('comment')) rules.push({ token: 'comment', foreground: fg, fontStyle: fontStyle || 'italic' });
                    });
                });
            }

            if (def.rules && Array.isArray(def.rules)) {
                def.rules.forEach(r => {
                    if (!r.foreground || !r.token) return;
                    rules.push({
                        token: r.token.trim(),
                        foreground: stripHash(r.foreground),
                        background: stripHash(r.background),
                        fontStyle: r.fontStyle
                    });
                });
            }

            const themeName = 'hw-' + (meta?.id || themeId);
            mon.editor.defineTheme(themeName, {
                base: def.base || 'vs-dark',
                inherit: def.inherit !== false,
                rules: rules.length > 0 ? rules : FALLBACK_LUA_RULES,
                colors: colors
            });
            mon.editor.setTheme(themeName);
        } catch (e) {
            console.error('[Theme Engine] Error applying editor theme:', e);
        }
    }

    getThemesList() {
        const seen = new Set();
        const list = [];
        for (const theme of Object.values(this.themeMetas)) {
            if (!theme || !theme.name) continue;
            const idKey = (theme.id || '').toLowerCase();
            const nameKey = theme.name.toLowerCase();
            if (seen.has(idKey) || seen.has(nameKey)) continue;
            seen.add(idKey);
            seen.add(nameKey);
            list.push(theme);
        }
        return list.sort((a, b) => a.name.localeCompare(b.name));
    }

    getCurrentTheme() {
        return this.themeMetas[this.currentThemeId] || { id: this.currentThemeId, name: this.currentThemeId };
    }

    subscribe(listener) {
        this.listeners.add(listener);
        return () => this.listeners.delete(listener);
    }

    notify() {
        const theme = this.getCurrentTheme();
        this.listeners.forEach(cb => cb(theme));
    }
}

export const themeService = new ThemeService();
window.getThemeIcon = (key, fallback) => themeService.getThemeIcon(key, fallback);
window.loadTheme = (id) => themeService.loadTheme(id);
