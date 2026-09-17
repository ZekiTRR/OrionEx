import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { useEditor } from '../../context/EditorContext';
import { themeService } from '../../services/themeService';
import { i18n } from '../../services/i18nService';

export function FilesystemTree({ searchQuery = '', onSelect }) {
    const { openFileInEditor } = useEditor();
    const [treeData, setTreeData] = useState([]);
    const [expandedFolders, setExpandedFolders] = useState(new Set());
    const [folderAccents, setFolderAccents] = useState({});
    const [contextMenu, setContextMenu] = useState(null);

    const loadScripts = async () => {
        try {
            const scripts = await window.hwAPI?.listScripts?.();
            if (scripts && Array.isArray(scripts)) {
                setTreeData(scripts);
            }
        } catch (e) {
            console.error('Error listing scripts:', e);
        }
    };

    const loadAccents = async () => {
        try {
            const fsConfig = await window.hwAPI?.getEditorConfig?.('filesystem');
            if (fsConfig && fsConfig.folderColors) {
                setFolderAccents(fsConfig.folderColors);
                localStorage.setItem('synapse_folder_accents', JSON.stringify(fsConfig.folderColors));
                return;
            }
            const saved = localStorage.getItem('synapse_folder_accents');
            if (saved) setFolderAccents(JSON.parse(saved));
        } catch (_) {}
    };

    useEffect(() => {
        loadScripts();
        loadAccents();
        return window.hwAPI?.onScriptsChanged?.(loadScripts);
    }, []);

    const toggleFolder = (path) => {
        setExpandedFolders(prev => {
            const next = new Set(prev);
            if (next.has(path)) next.delete(path);
            else next.add(path);
            return next;
        });
    };

    const handleFileClick = async (node) => {
        if (onSelect) { onSelect(node); return; }
        let content = '';
        try {
            const res = await window.hwAPI?.readScript?.(node.path);
            if (res && typeof res.content === 'string') {
                content = res.content;
            } else { window.HWToast?.error('Unable to read this file.'); return; }
        } catch (error) { window.HWToast?.error(error.message); return; }
        openFileInEditor(node.name, content, { isFile: true, filePath: node.path });
    };

    const handleFileContextMenu = (e, file) => {
        e.preventDefault();
        e.stopPropagation();

        const appEl = document.getElementById('application') || document.body;
        const appRect = appEl.getBoundingClientRect();
        const posX = Math.max(10, e.clientX - appRect.left);
        const posY = Math.max(10, e.clientY - appRect.top);

        setContextMenu({
            x: posX,
            y: posY,
            type: 'file',
            item: file
        });
    };

    const handleFolderContextMenu = (e, folder) => {
        e.preventDefault();
        e.stopPropagation();

        const appEl = document.getElementById('application') || document.body;
        const appRect = appEl.getBoundingClientRect();
        const posX = Math.max(10, e.clientX - appRect.left);
        const posY = Math.max(10, e.clientY - appRect.top);

        setContextMenu({
            x: posX,
            y: posY,
            type: 'folder',
            item: folder
        });
    };

    useEffect(() => {
        if (!contextMenu) return;

        const handleClick = (e) => {
            if (!e.target.closest('.hw-contextmenu')) {
                setContextMenu(null);
            }
        };
        const handleKeyDown = (e) => {
            if (e.key === 'Escape') setContextMenu(null);
        };

        const timer = setTimeout(() => {
            document.addEventListener('click', handleClick);
            document.addEventListener('contextmenu', handleClick);
        }, 10);
        document.addEventListener('keydown', handleKeyDown);

        return () => {
            clearTimeout(timer);
            document.removeEventListener('click', handleClick);
            document.removeEventListener('contextmenu', handleClick);
            document.removeEventListener('keydown', handleKeyDown);
        };
    }, [contextMenu]);

    const handleContextMenuAction = async (action) => {
        if (!contextMenu) return;
        const { type, item } = contextMenu;
        setContextMenu(null);

        if (type === 'file') {
            switch (action) {
                case 'execute': {
                    const res = await window.hwAPI?.readScript?.(item.path);
                    const code = res?.content || '';
                    if (code) window.hwAPI?.execute?.(code);
                    break;
                }
                case 'open':
                    handleFileClick(item);
                    break;
                case 'delete':
                    await window.hwAPI?.deleteScript?.(item.path);
                    loadScripts();
                    break;
                case 'open-in-folder':
                    window.hwAPI?.showItemInFolder?.(item.path);
                    break;
            }
        } else if (type === 'folder') {
            switch (action) {
                case 'delete':
                    await window.hwAPI?.deleteScript?.(item.path);
                    loadScripts();
                    break;
                case 'open-in-folder':
                    window.hwAPI?.showItemInFolder?.(item.path);
                    break;
                case 'set-accent': {
                    const color = await window.HWDialog?.promptSetAccent?.();
                    if (color !== null && color !== undefined) {
                        const nextAccents = { ...folderAccents };
                        if (color) {
                            nextAccents[item.path] = color;
                        } else {
                            delete nextAccents[item.path];
                        }
                        setFolderAccents(nextAccents);
                        localStorage.setItem('synapse_folder_accents', JSON.stringify(nextAccents));
                        try {
                            const cfg = (await window.hwAPI?.getEditorConfig?.('filesystem')) || {};
                            cfg.folderColors = nextAccents;
                            await window.hwAPI?.setEditorConfig?.('filesystem', cfg);
                        } catch (_) {}
                    }
                    break;
                }
            }
        }
    };

    const filterTree = (nodes, query) => {
        if (!query) return nodes;
        const q = query.toLowerCase();
        const result = [];
        for (const item of nodes) {
            if (item.isDirectory) {
                const nameMatch = item.name.toLowerCase().includes(q);
                const filteredChildren = filterTree(item.children || [], query);
                if (nameMatch || filteredChildren.length > 0) {
                    result.push({
                        ...item,
                        children: filteredChildren,
                        isAutoExpanded: true
                    });
                }
            } else {
                if (item.name.toLowerCase().includes(q)) {
                    result.push(item);
                }
            }
        }
        return result;
    };

    const renderNodes = (nodes) => {
        return nodes.map((item) => {
            if (item.isDirectory) {
                const isExpanded = !!searchQuery || item.isAutoExpanded || expandedFolders.has(item.path);
                const folderAccent = folderAccents[item.path] || '';
                const folderIconName = themeService.getThemeIcon('folder', 'fluent:folder-20-filled');

                return (
                    <div key={item.path} className="node">
                        <div>
                            <div
                                className="node-caption group flex items-center py-0.5 pl-1 opacity-70 hover:opacity-100 active:opacity-50 cursor-default"
                                draggable="true"
                                title={item.path}
                                onClick={(e) => {
                                    e.stopPropagation();
                                    toggleFolder(item.path);
                                }}
                                onContextMenu={(e) => handleFolderContextMenu(e, item)}
                            >
                                <iconify-icon
                                    icon="fluent:chevron-right-20-filled"
                                    class={`flex items-center justify-center transition-all ${
                                        isExpanded ? 'rotate-90 text-base' : 'rotate-0 text-[0] opacity-0 group-hover:text-base'
                                    }`}
                                />
                                <iconify-icon
                                    icon={folderIconName}
                                    class="flex items-center justify-center w-4 min-w-[1rem]"
                                    style={folderAccent ? { color: folderAccent } : undefined}
                                />
                                <div className="ml-2 overflow-ellipsis whitespace-nowrap">{item.name}</div>
                            </div>
                        </div>
                        <div className={`children ml-2 ${isExpanded ? '' : 'collapsed'}`}>
                            {item.children && renderNodes(item.children)}
                        </div>
                    </div>
                );
            }

            const ext = item.name.split('.').pop().toLowerCase();
            let iconName = themeService.getThemeIcon('file', 'fluent:document-20-filled');
            let iconStyle = { color: 'rgb(96, 165, 250)' };

            if (ext === 'lua' || ext === 'luau') {
                iconName = themeService.getThemeIcon('file-script') || themeService.getThemeIcon('file', 'file-icons:lua') || 'file-icons:lua';
            } else if (ext === 'txt') {
                iconName = themeService.getThemeIcon('file-text') || themeService.getThemeIcon('file', 'fluent:document-20-filled') || 'fluent:document-20-filled';
            }

            return (
                <div key={item.path} className="node">
                    <div>
                        <div
                            className="node-caption group flex items-center py-0.5 pl-1 opacity-70 hover:opacity-100 active:opacity-50 cursor-default"
                            draggable="true"
                            title={item.path}
                            onClick={() => handleFileClick(item)}
                            onContextMenu={(e) => handleFileContextMenu(e, item)}
                        >
                            <iconify-icon
                                icon={iconName}
                                class="flex items-center justify-center w-4 min-w-[1rem]"
                                style={iconStyle}
                            />
                            <div className="ml-2 overflow-ellipsis whitespace-nowrap">{item.name}</div>
                        </div>
                    </div>
                </div>
            );
        });
    };

    const displayNodes = filterTree(treeData, searchQuery);

    return (
        <>
            {renderNodes(displayNodes)}

            {/* Context Menu matching original DOM exactly (Portaled to prevent clipping) */}
            {contextMenu && createPortal(
                <div
                    className="hw-contextmenu pointer-events-auto absolute flex flex-col rounded-md"
                    style={{ left: `${contextMenu.x}px`, top: `${contextMenu.y}px`, zIndex: 1000 }}
                    onClick={(e) => e.stopPropagation()}
                >
                    {contextMenu.type === 'file' ? (
                        <>
                            <div
                                className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                onClick={() => handleContextMenuAction('execute')}
                            >
                                <iconify-icon icon="fluent:play-20-regular" class="flex items-center justify-center" />
                                <span>{i18n.t('contextmenu-execute', 'Execute')}</span>
                            </div>
                            <div
                                className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                onClick={() => handleContextMenuAction('open')}
                            >
                                <iconify-icon icon="fluent:document-arrow-up-20-filled" class="flex items-center justify-center" />
                                <span>{i18n.t('contextmenu-open', 'Open')}</span>
                            </div>
                            <div
                                className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                onClick={() => handleContextMenuAction('delete')}
                            >
                                <iconify-icon icon="fluent:delete-20-filled" class="flex items-center justify-center" />
                                <span>{i18n.t('contextmenu-delete', 'Delete')}</span>
                            </div>
                            <div
                                className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                onClick={() => handleContextMenuAction('open-in-folder')}
                            >
                                <iconify-icon icon="fluent:folder-20-filled" class="flex items-center justify-center" />
                                <span>{i18n.t('contextmenu-open-in-folder', 'Open in folder')}</span>
                            </div>
                        </>
                    ) : (
                        <>
                            <div
                                className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                onClick={() => handleContextMenuAction('delete')}
                            >
                                <iconify-icon icon="fluent:delete-20-filled" class="flex items-center justify-center" />
                                <span>{i18n.t('contextmenu-delete', 'Delete')}</span>
                            </div>
                            <div
                                className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                onClick={() => handleContextMenuAction('open-in-folder')}
                            >
                                <iconify-icon icon="fluent:folder-20-filled" class="flex items-center justify-center" />
                                <span>{i18n.t('contextmenu-open-in-folder', 'Open in folder')}</span>
                            </div>
                            <div
                                className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                onClick={() => handleContextMenuAction('set-accent')}
                            >
                                <iconify-icon icon="fluent:color-20-filled" class="flex items-center justify-center" />
                                <span>{i18n.t('contextmenu-set-accent', 'Set accent')}</span>
                            </div>
                        </>
                    )}
                </div>,
                document.getElementById('canvas-menus') || document.body
            )}
        </>
    );
}
