import React, { useState, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { useEditor } from '../../context/EditorContext';
import { themeService } from '../../services/themeService';
import { i18n } from '../../services/i18nService';

export function EditorTabs() {
    const { tabs, activeTabId, switchTab, closeTab, createTab, reorderTabs, handleTabAction } = useEditor();
    const [contextMenu, setContextMenu] = useState(null);
    const draggedTabIdRef = useRef(null);

    const openContextMenu = (tabId, clientX, clientY) => {
        const appEl = document.getElementById('application') || document.body;
        const appRect = appEl.getBoundingClientRect();
        const posX = Math.max(0, clientX - appRect.left);
        const posY = Math.max(0, clientY - appRect.top);

        setContextMenu({
            tabId,
            x: posX,
            y: posY
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

    const handleActionClick = (action) => {
        if (!contextMenu) return;
        const tabId = contextMenu.tabId;
        setContextMenu(null);
        handleTabAction(action, tabId);
    };

    const unsavedIconName = themeService.getThemeIcon('asterisk', 'fluent:text-asterisk-20-filled');
    const closeIconName = themeService.getThemeIcon('cross', 'fluent:dismiss-20-filled');
    const fileIconName = themeService.getThemeIcon('file', 'fluent:document-20-filled');

    return (
        <div className="tabs-container flex w-full items-center overflow-y-scroll border-b select-none">
            <div className="tabs flex" id="editor-tabs">
                {tabs.map((tab) => {
                    const isActive = tab.id === activeTabId;
                    const isDirty = (tab.content || '').replace(/\r\n/g, '\n') !== (tab.savedValue || '').replace(/\r\n/g, '\n');

                    const isBookmarkTab = !!(tab.isBookmark || tab.bookmarkUri || tab.customIcon === 'fluent:bookmark-20-filled');
                    const fileIcon = ((tab.isFile || tab.filePath) && !isBookmarkTab);

                    return (
                        <div
                            key={tab.id}
                            className={`hw-editor-tab-wrapper ${tab._isNew ? 'new-tab-anim' : ''}`}
                            data-tab-wrapper-id={String(tab.id)}
                        >
                            <div
                                draggable
                                className={`hw-editor-tab group relative flex min-w-[10rem] max-w-xs flex-col border-r p-0.5 cursor-pointer ${
                                    isActive ? 'select' : ''
                                }`}
                                onClick={(e) => {
                                    if (!e.target.closest('.close')) switchTab(tab.id);
                                }}
                                onDoubleClick={(e) => {
                                    if (e.target.closest('.close')) return;
                                    e.preventDefault();
                                    openContextMenu(tab.id, e.clientX, e.clientY);
                                }}
                                onContextMenu={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    openContextMenu(tab.id, e.clientX, e.clientY);
                                }}
                                onDragStart={(e) => {
                                    if (e.target.closest('.close')) {
                                        e.preventDefault();
                                        return;
                                    }
                                    draggedTabIdRef.current = tab.id;
                                    e.dataTransfer.effectAllowed = 'move';
                                    e.dataTransfer.setData('text/plain', String(tab.id));
                                    setTimeout(() => {
                                        e.currentTarget.style.opacity = '0.4';
                                    }, 0);
                                }}
                                onDragEnd={(e) => {
                                    draggedTabIdRef.current = null;
                                    e.currentTarget.style.opacity = '';
                                }}
                                onDragOver={(e) => {
                                    e.preventDefault();
                                    e.dataTransfer.dropEffect = 'move';
                                    const draggedId = draggedTabIdRef.current;
                                    if (!draggedId || draggedId === tab.id) return;

                                    const fromIdx = tabs.findIndex(t => t.id === draggedId);
                                    const toIdx = tabs.findIndex(t => t.id === tab.id);
                                    if (fromIdx === -1 || toIdx === -1 || fromIdx === toIdx) return;

                                    const rect = e.currentTarget.getBoundingClientRect();
                                    const mouseX = e.clientX;
                                    const threshold = rect.width * 0.25;

                                    if (fromIdx < toIdx && mouseX < rect.left + threshold) return;
                                    if (fromIdx > toIdx && mouseX > rect.right - threshold) return;

                                    reorderTabs(fromIdx, toIdx);
                                }}
                            >
                                <div className={`colorspace absolute top-0 flex h-full w-full ${isActive ? 'opacity-50' : 'opacity-0'}`} />
                                <div className={`content z-10 flex items-center p-1 ${isActive ? 'opacity-100' : 'opacity-50'}`}>
                                    <div className="icons mr-2 flex gap-1">
                                        {isDirty && (
                                            <iconify-icon icon={unsavedIconName} class="flex items-center justify-center text-amber-400" />
                                        )}
                                        {tab.pinned && (
                                            <iconify-icon icon="fluent:pin-12-filled" class="flex items-center justify-center" />
                                        )}
                                        {tab.readonly && (
                                            <iconify-icon icon="fluent:lock-20-filled" class="flex items-center justify-center" />
                                        )}
                                        {isBookmarkTab && (
                                            <iconify-icon icon="fluent:bookmark-20-filled" class="flex items-center justify-center" />
                                        )}
                                        {fileIcon && (
                                            <iconify-icon icon={fileIconName} class="flex items-center justify-center" />
                                        )}
                                        {/* Base icon (omega is always present!) */}
                                        <iconify-icon icon="mdi:omega" class="flex items-center justify-center" />
                                        {tab.customIcon && tab.customIcon !== 'fluent:bookmark-20-filled' && (
                                            <iconify-icon icon={tab.customIcon} class="flex items-center justify-center" />
                                        )}
                                    </div>

                                    <div className="caption overflow-hidden overflow-ellipsis whitespace-nowrap text-sm">
                                        {tab.title}
                                    </div>

                                    {!tab.pinned && (
                                        <div
                                            className="close ml-auto flex h-full items-center justify-center rounded transition hover:bg-white/10 active:opacity-50"
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                closeTab(tab.id);
                                            }}
                                            title="Close Tab"
                                        >
                                            <iconify-icon icon={closeIconName} class="flex items-center justify-center" />
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Add Tab Button */}
            <div
                className="add-tab flex w-8 self-stretch items-center justify-center opacity-50 transition hover:opacity-100 active:opacity-50 cursor-pointer"
                id="add-tab-btn"
                title="New Tab"
                onClick={() => createTab()}
            >
                <iconify-icon icon="fluent:add-20-filled" class="flex items-center justify-center" />
            </div>

            {/* Full Tab Context Menu with Nested Submenus (rendered via Portal on top of everything) */}
            {contextMenu && createPortal(
                <div
                    className="hw-contextmenu pointer-events-auto absolute flex flex-col rounded-md"
                    style={{ left: `${contextMenu.x}px`, top: `${contextMenu.y}px`, width: 'max-content', zIndex: 1000 }}
                    onClick={(e) => e.stopPropagation()}
                >
                    <div
                        className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                        onClick={() => handleActionClick('duplicate')}
                    >
                        <iconify-icon icon="fluent:clipboard-20-filled" class="flex items-center justify-center" />
                        <span>{i18n.t('contextmenu-duplicate', 'Duplicate')}</span>
                    </div>

                    <div
                        className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                        onClick={() => handleActionClick('execute')}
                    >
                        <iconify-icon icon="fluent:settings-20-filled" class="flex items-center justify-center" />
                        <span>{i18n.t('contextmenu-execute', 'Execute')}</span>
                    </div>

                    <div
                        className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                        onClick={() => handleActionClick('format')}
                    >
                        <iconify-icon icon="fluent:math-format-linear-24-filled" class="flex items-center justify-center" />
                        <span>{i18n.t('contextmenu-format', 'Format')}</span>
                    </div>

                    {/* Customize Submenu */}
                    <div
                        className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default group"
                    >
                        <iconify-icon icon="fluent:edit-20-filled" class="flex items-center justify-center" />
                        <span>{i18n.t('contextmenu-customize', 'Customize')}</span>
                        <iconify-icon icon="fluent:chevron-right-20-regular" class="flex items-center justify-center ml-auto" />
                        
                        <div className="submenu-container">
                            <div className="hw-contextmenu pointer-events-auto flex flex-col rounded-md">
                                <div
                                    className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                    onClick={() => handleActionClick('rename')}
                                >
                                    <iconify-icon icon="fluent:rename-24-filled" class="flex items-center justify-center" />
                                    <span>{i18n.t('contextmenu-rename', 'Rename')}</span>
                                </div>
                                <div
                                    className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                    onClick={() => handleActionClick('toggle-pin')}
                                >
                                    <iconify-icon icon="fluent:pin-12-filled" class="flex items-center justify-center" />
                                    <span>{i18n.t('contextmenu-toggle-pin', 'Toggle pin')}</span>
                                </div>
                                <div
                                    className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                                    onClick={() => handleActionClick('toggle-readonly')}
                                >
                                    <iconify-icon icon="fluent:lock-20-filled" class="flex items-center justify-center" />
                                    <span>{i18n.t('contextmenu-toggle-readonly', 'Toggle readonly')}</span>
                                </div>

                                {/* Set Icon Submenu */}
                                <div
                                    className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default group"
                                >
                                    <iconify-icon icon="fluent:icons-24-filled" class="flex items-center justify-center" />
                                    <span>{i18n.t('contextmenu-set-icon', 'Set icon')}</span>
                                    <iconify-icon icon="fluent:chevron-right-20-regular" class="flex items-center justify-center ml-auto" />

                                    <div className="submenu-container">
                                        <div className="hw-contextmenu pointer-events-auto flex flex-col rounded-md">
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-none')}>
                                                <iconify-icon icon="fluent:border-none-24-filled" class="flex items-center justify-center" />
                                                <span>None</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-star')}>
                                                <iconify-icon icon="fluent:star-24-filled" class="flex items-center justify-center" />
                                                <span>Star</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-lightbulb')}>
                                                <iconify-icon icon="fluent:lightbulb-24-filled" class="flex items-center justify-center" />
                                                <span>Lightbulb</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-turbo')}>
                                                <iconify-icon icon="fluent:flash-24-filled" class="flex items-center justify-center" />
                                                <span>Turbo</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-commands')}>
                                                <iconify-icon icon="fluent:window-console-20-filled" class="flex items-center justify-center" />
                                                <span>Commands</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-beaker')}>
                                                <iconify-icon icon="fluent:beaker-24-filled" class="flex items-center justify-center" />
                                                <span>Beaker</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-shield')}>
                                                <iconify-icon icon="fluent:shield-24-filled" class="flex items-center justify-center" />
                                                <span>Shield</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-chess')}>
                                                <iconify-icon icon="fluent:chess-20-filled" class="flex items-center justify-center" />
                                                <span>Chess</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-swords')}>
                                                <iconify-icon icon="ri:sword-fill" class="flex items-center justify-center" />
                                                <span>Swords</span>
                                            </div>
                                            <div className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default" onClick={() => handleActionClick('set-icon-rabbit')}>
                                                <iconify-icon icon="fluent:animal-rabbit-24-filled" class="flex items-center justify-center" />
                                                <span>Rabbit</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div
                        className="entry relative flex items-center gap-2 py-1 px-2 min-w-[10rem] whitespace-nowrap cursor-default"
                        onClick={() => handleActionClick('close-others')}
                    >
                        <iconify-icon icon="fluent:dismiss-square-multiple-20-filled" class="flex items-center justify-center" />
                        <span>{i18n.t('contextmenu-close-others', 'Close all but this')}</span>
                    </div>
                </div>,
                document.getElementById('canvas-menus') || document.body
            )}
        </div>
    );
}
