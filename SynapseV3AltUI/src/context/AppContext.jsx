import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { i18n } from '../services/i18nService';
import { themeService } from '../services/themeService';
import { normalizeFontSize } from '../services/editorFont';

const AppContext = createContext(null);

export function AppProvider({ children }) {
    const [activePage, setActivePage] = useState('editor');
    const [classicMenuOpen, setClassicMenuOpen] = useState(false);
    const [currentLanguage, setCurrentLanguage] = useState(i18n.getLanguage());

    // Settings state
    const [settings, setSettings] = useState({
        always_on_top: localStorage.getItem('synapse_setting_always_on_top') === 'true',
        classic_layout: localStorage.getItem('synapse_setting_classic_layout') === 'true',
        compact_tabs: localStorage.getItem('synapse_setting_compact_tabs') === 'true',
        compact_btns: localStorage.getItem('synapse_setting_compact_btns') === 'true',
        navbarstyle: localStorage.getItem('synapse_setting_navbarstyle') || '0',
        editorstyle: localStorage.getItem('synapse_setting_editorstyle') || '0',
        actionbar_direction: localStorage.getItem('synapse_setting_actionbar_direction') || '1',
        sidebarlayout: localStorage.getItem('synapse_setting_sidebarlayout') || '1',
        interface_scale: parseInt(localStorage.getItem('synapse_setting_interface_scale') || '100', 10),
        animate_collapse: localStorage.getItem('synapse_setting_animate_collapse') === 'true',
        transparent_window: localStorage.getItem('synapse_setting_transparent_window') === 'true',
        fontsize: normalizeFontSize(localStorage.getItem('synapse_setting_fontsize')),
        fontfamily: localStorage.getItem('synapse_setting_fontfamily') || '',
        word_wrap: localStorage.getItem('synapse_setting_word_wrap') === 'true',
        smooth_cursor: localStorage.getItem('synapse_setting_smooth_cursor') !== 'false',
        smooth_movement: localStorage.getItem('synapse_setting_smooth_movement') !== 'false',
        tab_length: parseInt(localStorage.getItem('synapse_setting_tab_length') || '4', 10),
        minimap: parseInt(localStorage.getItem('synapse_setting_minimap') || '1', 10),
        unsaved_warnings: localStorage.getItem('synapse_setting_unsaved_warnings') !== 'false',
        default_tab_content: localStorage.getItem('synapse_setting_default_tab_content') ?? "print('Synapse winning!')",
        lua_language_server: localStorage.getItem('synapse_setting_lua_language_server') !== 'false',
        log_lsp_errors: localStorage.getItem('synapse_setting_log_lsp_errors') === 'true',
        max_log_count: parseInt(localStorage.getItem('synapse_setting_max_log_count') || '720', 10),
        show_console_at_launch: localStorage.getItem('synapse_setting_show_console_at_launch') === 'true',
        toast_scale: parseInt(localStorage.getItem('synapse_setting_toast_scale') || '100', 10),
        language: localStorage.getItem('synapse_setting_language') || 'english',
    });

    // Active Dialog state
    const [activeDialog, setActiveDialog] = useState(null);

    // Active Toasts
    const [toasts, setToasts] = useState([]);

    // Active Progress Task Cards
    const [progressViews, setProgressViews] = useState(new Map());

    // Subscribe to i18n
    useEffect(() => {
        return i18n.subscribe((lang) => {
            setCurrentLanguage(lang);
        });
    }, []);

    useEffect(() => window.hwAPI.onSettingsChanged(payload => {
        const changes = payload?.key ? { [payload.key]: payload.value } : (payload?.settings || payload || {});
        setSettings(prev => ({ ...prev, ...changes }));
    }), []);

    // Sync layout classes to #application, body, and html
    useEffect(() => {
        const rootElements = [document.documentElement, document.body, document.getElementById('application')].filter(Boolean);

        rootElements.forEach(el => {
            el.classList.toggle('classic-layout', !!settings.classic_layout);
            el.classList.toggle('compact-tabs', !!settings.compact_tabs);
            el.classList.toggle('compact-btns', !!settings.compact_btns);
            el.classList.toggle('left-nav-layout', settings.navbarstyle === '1');
            el.classList.toggle('animate-collapse', !!settings.animate_collapse);
        });

        const scale = settings.interface_scale / 100;
        if (window.hwAPI?.setZoomFactor) {
            window.hwAPI.setZoomFactor(scale);
        }

        document.documentElement.style.setProperty('--toast-scale', (settings.toast_scale / 100).toString());
    }, [settings]);

    const updateSetting = useCallback((key, value) => {
        if (key === 'fontsize') value = normalizeFontSize(value);
        setSettings(prev => ({ ...prev, [key]: value }));
        localStorage.setItem(`synapse_setting_${key}`, String(value));
        window.hwAPI?.setSetting?.(key, value);

        if (key === 'language') {
            i18n.setLanguage(value);
        }
    }, []);

    const resetAllSettings = useCallback(() => {
        // Reset preferences only: tabs/bookmarks/extra storage remain intact.
        const defaults = {
            classic_layout: false,
            compact_tabs: false,
            compact_btns: false,
            navbarstyle: '0',
            editorstyle: '0',
            actionbar_direction: '1',
            sidebarlayout: '1',
            interface_scale: 100,
            animate_collapse: false,
            transparent_window: false,
            fontsize: 16,
            fontfamily: '',
            word_wrap: false,
            smooth_cursor: true,
            smooth_movement: true,
            tab_length: 4,
            minimap: 1,
            unsaved_warnings: true,
            default_tab_content: "print('Synapse winning!')",
            lua_language_server: true,
            log_lsp_errors: false,
            max_log_count: 720,
            show_console_at_launch: false,
            toast_scale: 100,
            language: 'english',
        };
        setSettings(defaults);
        Object.entries(defaults).forEach(([k, v]) => {
            localStorage.setItem(`synapse_setting_${k}`, String(v));
            window.hwAPI?.setSetting?.(k, v);
        });
        i18n.setLanguage('english');
        themeService.loadTheme('hollywood-dark');
    }, []);

    // ── Dialog Provider ──
    const spawnDialog = useCallback((dialogConfig) => {
        return new Promise((resolve) => {
            setActiveDialog({
                ...dialogConfig,
                onClose: (buttonIndex, value) => {
                    setActiveDialog(null);
                    resolve({ button: buttonIndex, value });
                }
            });
        });
    }, []);

    // ── Toast Provider ──
    const showToast = useCallback((toastConfig) => {
        const id = 'toast-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6);
        const newToast = {
            id,
            ...toastConfig,
            onDismiss: () => {
                setToasts(prev => prev.filter(t => t.id !== id));
                toastConfig.onDismiss?.();
            }
        };
        setToasts(prev => [...prev, newToast]);
        return {
            dismiss: () => newToast.onDismiss()
        };
    }, []);

    // ── Progress View Provider ──
    const addProgressTask = useCallback((config = {}) => {
        const rawHeader = config.header || config.Header || config.title || config.Title || 'Tasks';
        const header = rawHeader.trim();
        const taskId = 'task-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6);

        let taskRef = {
            id: taskId,
            header,
            desc: config.desc || config.text || '',
            subDesc: config.subDesc || config.subtext || '',
            state: config.state || 'in-progress',
            icon: config.icon || 'fluent:checkmark-20-filled',
            autoDismiss: config.autoDismiss !== undefined ? config.autoDismiss : (config.autodismiss !== undefined ? config.autodismiss : (config.duration !== undefined ? config.duration : undefined))
        };

        setProgressViews(prev => {
            const next = new Map(prev);
            const tasks = next.get(header) || [];
            next.set(header, [...tasks, taskRef]);
            return next;
        });

        const controller = {
            update: (updates) => {
                taskRef = {
                    ...taskRef,
                    ...updates,
                    autoDismiss: updates.autoDismiss !== undefined ? updates.autoDismiss : (updates.autodismiss !== undefined ? updates.autodismiss : (updates.duration !== undefined ? updates.duration : taskRef.autoDismiss))
                };
                setProgressViews(prev => {
                    const next = new Map(prev);
                    const tasks = next.get(header) || [];
                    next.set(header, tasks.map(t => t.id === taskId ? taskRef : t));
                    return next;
                });
            },
            dismiss: () => {
                setProgressViews(prev => {
                    const next = new Map(prev);
                    const tasks = (next.get(header) || []).filter(t => t.id !== taskId);
                    if (tasks.length === 0) {
                        next.delete(header);
                    } else {
                        next.set(header, tasks);
                    }
                    return next;
                });
            }
        };

        return controller;
    }, []);

    // Global backwards-compatibility bridge for window.HWDialog and window.HW
    useEffect(() => {
        window.HWDialog = {
            spawn: spawnDialog,
            promptRenameTab(currentTitle = '') {
                return spawnDialog({
                    icon: 'fluent:edit-20-filled',
                    iconColor: 'white',
                    title: i18n.t('dialog-renametab-title', 'Rename tab'),
                    body: i18n.t('dialog-renametab-body', 'Input the new tab name below.'),
                    textbox: currentTitle,
                    buttons: [i18n.t('dialog-ok', 'Ok'), i18n.t('dialog-cancel', 'Cancel')]
                }).then(({ button, value }) => (button === 0 && value && value.trim() ? value.trim() : null));
            },
            confirm({ title, message, icon = 'fluent:warning-20-filled', iconColor = '#fbbf24', confirmText = null, cancelText = null }) {
                return spawnDialog({
                    icon,
                    iconColor,
                    title,
                    body: message,
                    buttons: [confirmText || i18n.t('dialog-yes', 'Yes'), cancelText || i18n.t('dialog-no', 'No')]
                }).then(({ button }) => button === 0);
            },
            confirmEraseUnsaved() {
                return spawnDialog({
                    icon: 'fluent:warning-20-filled',
                    title: i18n.t('warning-erase-title', 'Erase unsaved content'),
                    body: i18n.t('warning-erase-text', 'Are you sure you want to do this? All unsaved code will be erased!'),
                    buttons: [i18n.t('dialog-yes', 'Yes'), i18n.t('dialog-no', 'No')]
                }).then(({ button }) => button === 0);
            },
            promptAddBookmark() {
                return spawnDialog({
                    icon: 'fluent:bookmark-add-20-filled',
                    iconColor: 'white',
                    title: i18n.t('dialog-addbookmark-title', 'Add bookmark'),
                    body: i18n.t('dialog-addbookmark-body', "Insert your bookmark's URI below."),
                    textbox: '',
                    buttons: [i18n.t('dialog-ok', 'Ok'), i18n.t('dialog-cancel', 'Cancel')]
                }).then(({ button, value }) => (button === 0 && value ? value : null));
            },
            alertInvalidBookmark() {
                return spawnDialog({
                    icon: 'fluent:bookmark-add-20-filled',
                    iconColor: 'white',
                    title: i18n.t('dialog-addbookmark-title', 'Add bookmark'),
                    body: i18n.t('dialog-invalidbookmark-body', 'URL is invalid. Please try again'),
                    buttons: [i18n.t('dialog-ok', 'Ok')]
                });
            },
            promptBookmarkName() {
                return spawnDialog({
                    icon: 'fluent:bookmark-add-20-filled',
                    iconColor: 'white',
                    title: i18n.t('dialog-bookmarkname-title', 'Bookmark name'),
                    body: i18n.t('dialog-bookmarkname-body', 'Choose a name for your bookmark. If none is provided, it will default to the filename.'),
                    textbox: '',
                    buttons: [i18n.t('dialog-ok', 'Ok'), i18n.t('dialog-cancel', 'Cancel')]
                }).then(({ button, value }) => (button === 0 ? (value !== null ? value.trim() : '') : null));
            },
            promptSetAccent() {
                return spawnDialog({
                    type: 'accent-picker',
                    title: i18n.t('dialog-setaccent-title', 'Set accent'),
                }).then(({ button, value }) => (button === 0 ? value : null));
            },
            confirmThemeOverrides() {
                return spawnDialog({
                    icon: 'mdi:palette-outline',
                    iconColor: 'white',
                    title: i18n.t('dialog-themesettings-title', 'Theme settings'),
                    body: i18n.t('dialog-themesettings-body', 'This theme has special setting overrides. Do you want to apply them?'),
                    buttons: [i18n.t('dialog-yes', 'Yes'), i18n.t('dialog-no', 'No')]
                }).then(({ button }) => button === 0);
            }
        };

        window.HW = {
            addMessage: addProgressTask,
            addTask: addProgressTask,
            dismissHeader: (header) => {
                setProgressViews(prev => {
                    const next = new Map(prev);
                    next.delete(header);
                    return next;
                });
            },
            dismissAll: () => setProgressViews(new Map())
        };

        window.HWToast = {
            spawn: showToast,
            show: showToast,
            info: (desc, subDesc = '', header = 'Information') => showToast({ header, desc, subDesc, type: 'info' }),
            warn: (desc, subDesc = '', header = 'Warning') => showToast({ header, desc, subDesc, type: 'warning' }),
            error: (desc, subDesc = '', header = 'Error') => showToast({ header, desc, subDesc, type: 'error' }),
            success: (desc, subDesc = '', header = 'Success') => showToast({ header, desc, subDesc, type: 'success' }),
            task: (desc, subDesc = '', header = 'Tasks') => addProgressTask({ header, desc, subDesc }),
        };
    }, [spawnDialog, showToast, addProgressTask]);

    return (
        <AppContext.Provider
            value={{
                activePage,
                setActivePage,
                classicMenuOpen,
                setClassicMenuOpen,
                settings,
                updateSetting,
                resetAllSettings,
                activeDialog,
                spawnDialog,
                toasts,
                showToast,
                progressViews,
                addProgressTask,
                currentLanguage
            }}
        >
            {children}
        </AppContext.Provider>
    );
}

export function useApp() {
    return useContext(AppContext);
}
