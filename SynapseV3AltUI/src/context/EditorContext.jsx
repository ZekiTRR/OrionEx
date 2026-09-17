import React, { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react';
import { useApp } from './AppContext';
import { setWorkspaceReader, saveWorkspace, reportError } from '../bridge';
import { formatLuaCode } from '../services/luaFormatter';

const EditorContext = createContext(null);

const newTabId = () => crypto.randomUUID();

export function EditorProvider({ children }) {
    const { spawnDialog } = useApp();
    const [tabs, setTabs] = useState(() => {
        try {
            const saved = localStorage.getItem('synapse_tabs');
            if (saved) {
                const parsed = JSON.parse(saved);
                if (Array.isArray(parsed) && parsed.length > 0) {
                    return parsed;
                }
            }
        } catch (_) {}

        const defaultContent = localStorage.getItem('synapse_setting_default_tab_content') ?? "print('Synapse winning!')";
        return [{
            id: newTabId(),
            title: 'Untitled tab',
            content: defaultContent,
            savedValue: defaultContent,
            isFile: false,
            filePath: null,
            isBookmark: false,
            bookmarkUri: null,
            pinned: false,
            readonly: false,
            customIcon: null
        }];
    });

    const [activeTabId, setActiveTabId] = useState(() => { const saved = localStorage.getItem('synapse_active_tab'); return tabs.find(t => String(t.id) === saved)?.id || tabs[0]?.id; });
    const monacoEditorRef = useRef(null);
    const modelsRef = useRef(new Map());

    // The native close handler can synchronously snapshot the current Monaco models.
    const snapshotRef = useRef(null);
    snapshotRef.current = () => ({
        tabs: tabs.map(t => ({ ...t, content: modelsRef.current.get(t.id)?.getValue() ?? t.content ?? '',
            extension: t.extension || (t.filePath || t.title || '').match(/\.[^.\/]+$/)?.[0] || '.lua' })),
        activeTabId: tabs.some(t => t.id === activeTabId) ? activeTabId : tabs[0]?.id || null
    });
    useEffect(() => { setWorkspaceReader(() => snapshotRef.current()); }, []);
    useEffect(() => {
        const timer = setTimeout(() => {
            const workspace = snapshotRef.current();
            localStorage.setItem('synapse_tabs', JSON.stringify(workspace.tabs));
            localStorage.setItem('synapse_active_tab', String(workspace.activeTabId || ''));
            saveWorkspace(workspace);
        }, 300);
        for (const [id, model] of modelsRef.current) if (!tabs.some(t => t.id === id)) { model.dispose(); modelsRef.current.delete(id); }
        return () => clearTimeout(timer);
    }, [tabs, activeTabId]);

    const activeTab = tabs.find(t => t.id === activeTabId) || tabs[0];

    const createTab = useCallback((title = 'Untitled tab', content = null) => {
        const id = newTabId();
        const initialContent = content !== null ? content : (localStorage.getItem('synapse_setting_default_tab_content') ?? "print('Synapse winning!')");
        const newTab = {
            id,
            title,
            content: initialContent,
            savedValue: initialContent,
            isFile: false,
            filePath: null,
            isBookmark: false,
            bookmarkUri: null,
            pinned: false,
            readonly: false,
            customIcon: null,
            _isNew: true
        };
        setTabs(prev => [...prev, newTab]);
        setActiveTabId(id);
        return id;
    }, []);

    const openFileInEditor = useCallback((name, content, options = {}) => {
        const isFile = options.isFile !== undefined ? options.isFile : (!!options.filePath);

        // Check existing
        const existing = tabs.find(t =>
            (options.filePath && t.filePath === options.filePath) ||
            (options.bookmarkUri && t.bookmarkUri === options.bookmarkUri)
        );

        if (existing) {
            setTabs(prev => prev.map(t => {
                if (t.id === existing.id) {
                    return {
                        ...t,
                        isFile: isFile || t.isFile,
                        filePath: options.filePath || t.filePath,
                        isBookmark: options.isBookmark || t.isBookmark,
                        bookmarkUri: options.bookmarkUri || t.bookmarkUri,
                        customIcon: options.customIcon || t.customIcon
                    };
                }
                return t;
            }));
            setActiveTabId(existing.id);
            return existing.id;
        }

        const id = newTabId();
        const newTab = {
            id,
            title: name,
            content: content || '',
            savedValue: content || '',
            isFile: !!isFile,
            filePath: options.filePath || null,
            isBookmark: !!options.isBookmark,
            bookmarkUri: options.bookmarkUri || null,
            pinned: !!options.pinned,
            readonly: !!options.readonly,
            customIcon: options.customIcon || null,
            _isNew: true
        };
        setTabs(prev => [...prev, newTab]);
        setActiveTabId(id);
        return id;
    }, [tabs]);

    const closeTab = useCallback(async (id) => {
        const tab = tabs.find(t => t.id === id);
        if (!tab) return;

        const isDirty = (tab.content || '').replace(/\r\n/g, '\n') !== (tab.savedValue || '').replace(/\r\n/g, '\n');
        const warnUnsaved = localStorage.getItem('synapse_setting_unsaved_warnings') !== 'false';

        if (warnUnsaved && isDirty && window.HWDialog?.confirmEraseUnsaved) {
            const confirmed = await window.HWDialog.confirmEraseUnsaved();
            if (!confirmed) return;
        }

        const nextTabs = tabs.filter(t => t.id !== id);
        if (nextTabs.length === 0) {
            const newId = newTabId();
            const def = localStorage.getItem('synapse_setting_default_tab_content') ?? "print('Synapse winning!')";
            setTabs([{
                id: newId,
                title: 'Untitled tab',
                content: def,
                savedValue: def,
                isFile: false,
                filePath: null,
                isBookmark: false,
                bookmarkUri: null,
                pinned: false,
                readonly: false,
                customIcon: null
            }]);
            setActiveTabId(newId);
        } else {
            setTabs(nextTabs);
            if (activeTabId === id) {
                const idx = tabs.findIndex(t => t.id === id);
                const nextActive = nextTabs[Math.max(0, idx - 1)];
                setActiveTabId(nextActive.id);
            }
        }
    }, [tabs, activeTabId]);

    const switchTab = useCallback((id) => {
        setActiveTabId(id);
    }, []);

    const updateTabContent = useCallback((id, newContent) => {
        setTabs(prev => prev.map(t => {
            if (t.id === id) {
                return { ...t, content: newContent };
            }
            return t;
        }));
    }, []);

    const saveActiveScript = useCallback(async () => {
        const tab = tabs.find(t => t.id === activeTabId);
        if (!tab) return;
        const content = tab.content || '';

        let targetPath = tab.filePath || (tab.isFile ? tab.title : null);
        if (!targetPath && tab.title && (tab.title.endsWith('.lua') || tab.title.endsWith('.luau') || tab.title.endsWith('.txt'))) {
            targetPath = tab.title;
        }

        if (targetPath) {
            let wrote = false;
            if (window.hwAPI?.saveScript) {
                try {
                    const res = await window.hwAPI.saveScript(targetPath, content);
                    if (res?.ok === true) {
                        targetPath = res.filePath || targetPath;
                        wrote = true;
                    }
                } catch (_) {}
            }
            if (!wrote) { reportError('Script save failed. Unsaved changes have been retained.'); return false; }
            setTabs(prev => prev.map(t => {
                if (t.id === activeTabId) {
                    return { ...t, isFile: true, filePath: targetPath, savedValue: content };
                }
                return t;
            }));
            return;
        }

        // New unsaved tab dialog
        const res = await window.hwAPI?.saveFile?.(content);
        if (res?.name && res.filePath && !res.error) {
            setTabs(prev => prev.map(t => {
                if (t.id === activeTabId) {
                    return {
                        ...t,
                        title: res.name,
                        filePath: res.filePath || res.path || null,
                        isFile: true,
                        savedValue: content
                    };
                }
                return t;
            }));
        }
    }, [tabs, activeTabId]);

    const reorderTabs = useCallback((fromIdx, toIdx) => {
        if (fromIdx === toIdx || fromIdx < 0 || toIdx < 0) return;
        setTabs(prev => {
            const next = [...prev];
            const [moved] = next.splice(fromIdx, 1);
            next.splice(toIdx, 0, moved);
            return next;
        });
    }, []);

    const handleTabAction = useCallback(async (action, tabId) => {
        const tab = tabs.find(t => t.id === tabId);
        if (!tab) return;

        switch (action) {
            case 'duplicate':
                createTab((tab.title || 'Untitled tab') + ' (Copy)', tab.content);
                break;
            case 'execute':
                window.hwAPI?.execute?.(tab.content || '');
                break;
            case 'format': {
                const formatted = formatLuaCode(tab.content || '');
                updateTabContent(tabId, formatted);
                if (tabId === activeTabId && monacoEditorRef.current) {
                    const model = monacoEditorRef.current.getModel();
                    if (model) model.setValue(formatted);
                }
                break;
            }
            case 'rename': {
                const newTitle = await window.HWDialog?.promptRenameTab(tab.title);
                if (newTitle && newTitle.trim()) {
                    setTabs(prev => prev.map(t => t.id === tabId ? { ...t, title: newTitle.trim() } : t));
                }
                break;
            }
            case 'toggle-pin':
                setTabs(prev => prev.map(t => t.id === tabId ? { ...t, pinned: !t.pinned } : t));
                break;
            case 'toggle-readonly':
                setTabs(prev => prev.map(t => t.id === tabId ? { ...t, readonly: !t.readonly } : t));
                if (tabId === activeTabId && monacoEditorRef.current) {
                    monacoEditorRef.current.updateOptions({ readOnly: !tab.readonly });
                }
                break;
            case 'set-icon-none':
                setTabs(prev => prev.map(t => t.id === tabId ? { ...t, customIcon: null } : t));
                break;
            case 'set-icon-star':
            case 'set-icon-lightbulb':
            case 'set-icon-turbo':
            case 'set-icon-commands':
            case 'set-icon-beaker':
            case 'set-icon-shield':
            case 'set-icon-chess':
            case 'set-icon-swords':
            case 'set-icon-rabbit': {
                const iconMap = {
                    'set-icon-star': 'fluent:star-24-filled',
                    'set-icon-lightbulb': 'fluent:lightbulb-24-filled',
                    'set-icon-turbo': 'fluent:flash-24-filled',
                    'set-icon-commands': 'fluent:window-console-20-filled',
                    'set-icon-beaker': 'fluent:beaker-24-filled',
                    'set-icon-shield': 'fluent:shield-24-filled',
                    'set-icon-chess': 'fluent:chess-20-filled',
                    'set-icon-swords': 'ri:sword-fill',
                    'set-icon-rabbit': 'fluent:animal-rabbit-24-filled',
                };
                setTabs(prev => prev.map(t => t.id === tabId ? { ...t, customIcon: iconMap[action] } : t));
                break;
            }
            case 'close-others':
                setActiveTabId(tabId);
                setTabs(prev => prev.filter(t => t.id === tabId || t.pinned));
                break;
        }
    }, [tabs, activeTabId, createTab, updateTabContent]);

    // Keyboard shortcut: Ctrl+S
    useEffect(() => {
        const handler = (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
                e.preventDefault();
                saveActiveScript();
            }
        };
        window.addEventListener('keydown', handler);
        return () => window.removeEventListener('keydown', handler);
    }, [saveActiveScript]);

    return (
        <EditorContext.Provider
            value={{
                tabs,
                activeTabId,
                activeTab,
                createTab,
                closeTab,
                switchTab,
                openFileInEditor,
                updateTabContent,
                saveActiveScript,
                reorderTabs,
                handleTabAction,
                monacoEditorRef,
                modelsRef
            }}
        >
            {children}
        </EditorContext.Provider>
    );
}

export function useEditor() {
    return useContext(EditorContext);
}
