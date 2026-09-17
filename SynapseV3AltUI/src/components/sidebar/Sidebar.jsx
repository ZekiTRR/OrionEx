import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import { FilesystemTree } from './FilesystemTree';
import { BookmarksList } from './BookmarksList';
import { GistsList } from './GistsList';

export function Sidebar() {
    const { settings } = useApp();
    const [width, setWidth] = useState(() => {
        const saved = parseInt(localStorage.getItem('synapse_sidebar_width') || '285', 10);
        return !isNaN(saved) && saved >= 150 && saved <= 450 ? saved : 285;
    });

    const [searchQuery, setSearchQuery] = useState('');
    const [fsCollapsed, setFsCollapsed] = useState(false);
    const [bmCollapsed, setBmCollapsed] = useState(false);
    const [gistsCollapsed, setGistsCollapsed] = useState(false);
    const [isDragging, setIsDragging] = useState(false);

    const isLeftSidebar = settings.sidebarlayout === '0';

    const handleMouseDown = (e) => {
        e.preventDefault();
        setIsDragging(true);
    };

    useEffect(() => {
        if (!isDragging) return;

        const handleMouseMove = (e) => {
            let newWidth = isLeftSidebar ? e.clientX : window.innerWidth - e.clientX;
            newWidth = Math.max(150, Math.min(450, newWidth));
            setWidth(newWidth);
        };

        const handleMouseUp = () => {
            setIsDragging(false);
            localStorage.setItem('synapse_sidebar_width', String(width));
        };

        window.addEventListener('mousemove', handleMouseMove);
        window.addEventListener('mouseup', handleMouseUp);

        return () => {
            window.removeEventListener('mousemove', handleMouseMove);
            window.removeEventListener('mouseup', handleMouseUp);
        };
    }, [isDragging, isLeftSidebar, width]);

    const [choosingBookmark, setChoosingBookmark] = useState(false);
    const [gistRevision, setGistRevision] = useState(0);
    const handleAddBookmark = () => { setBmCollapsed(false); setChoosingBookmark(value => !value); };
    const bookmarkFile = async file => {
        const bookmarks = await window.hwAPI.getSetting('bookmarks', []) || [];
        if (!bookmarks.some(item => item.path?.toLowerCase() === file.path.toLowerCase())) {
            if (!await window.hwAPI.setSetting('bookmarks', [...bookmarks, { name: file.name, path: file.path }])) return;
        }
        setChoosingBookmark(false);
    };
    const addGist = async () => {
        const result = await window.HWDialog.spawn({
            title: 'Add GitHub Gist', body: 'Paste an HTTPS raw Gist or GitHub file URL.',
            textbox: '', buttons: ['Add', 'Cancel']
        });
        if (result.button !== 0 || !result.value?.trim()) return;
        if (await window.hwAPI.addGist(result.value.trim())) setGistRevision(value => value + 1);
    };

    return (
        <div
            id="sidebar-wrapper"
            style={{
                position: 'relative',
                userSelect: 'auto',
                width: `${width}px`,
                height: '100%',
                maxWidth: '450px',
                minWidth: '150px',
                boxSizing: 'border-box',
                flexShrink: 0
            }}
        >
            <div className={`sidebar h-full ${isLeftSidebar ? 'border-r' : 'border-l'}`}>
                <div className="tree flex h-full flex-col gap-0.5">
                    {/* Search Textbox */}
                    <div className="hw-textbox rounded-md px-2 py-1">
                        <div className="inner flex items-center gap-2">
                            <iconify-icon icon="heroicons:magnifying-glass" class="flex items-center justify-center" />
                            <input
                                id="sidebar-search-input"
                                className="w-full border-none bg-transparent text-inherit outline-none"
                                type="text"
                                autoComplete="off"
                                spellCheck="false"
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                            />
                        </div>
                    </div>

                    <div className="min-h-0 flex-1 overflow-y-auto">
                        {/* Module 1: Local Filesystem */}
                        <div
                            className="module-caption group sticky top-0 z-10 flex items-center border-y p-0.5 cursor-pointer"
                            onClick={() => setFsCollapsed(!fsCollapsed)}
                        >
                            <iconify-icon
                                icon="heroicons:chevron-down"
                                class={`flex items-center justify-center chevron text-[0] opacity-50 transition-all hover:opacity-100 group-hover:text-base ${
                                    fsCollapsed ? 'rotate-180' : 'rotate-0'
                                }`}
                            />
                            <div className="text text-base">
                                <div className="flex items-center gap-1 text-blue-400">
                                    <iconify-icon icon="fluent:hard-drive-20-filled" class="flex items-center justify-center text-lg" />
                                    <span>Local Filesystem</span>
                                </div>
                            </div>
                        </div>
                        <div className={`module w-full overflow-x-hidden ${fsCollapsed ? 'collapsed' : ''}`} id="module-filesystem">
                            <FilesystemTree searchQuery={searchQuery} />
                        </div>

                        {/* Module 2: Bookmarks */}
                        <div
                            className="module-caption group sticky top-0 z-10 flex items-center border-y p-0.5 cursor-pointer"
                            onClick={() => setBmCollapsed(!bmCollapsed)}
                        >
                            <iconify-icon
                                icon="heroicons:chevron-down"
                                class={`flex items-center justify-center chevron text-[0] opacity-50 transition-all hover:opacity-100 group-hover:text-base ${
                                    bmCollapsed ? 'rotate-180' : 'rotate-0'
                                }`}
                            />
                            <div className="text text-base">
                                <div className="flex items-center gap-1 text-yellow-400">
                                    <iconify-icon icon="fluent:bookmark-20-filled" class="flex items-center justify-center text-lg" />
                                    <span>Bookmarks</span>
                                </div>
                            </div>
                            <div className="actions ml-auto mr-1 flex text-base">
                                <div
                                    className="active:opacity-50 cursor-pointer"
                                    title="Add bookmark"
                                    id="add-bookmark-btn"
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        handleAddBookmark();
                                    }}
                                >
                                    <iconify-icon icon="fluent:add-20-filled" class="flex items-center justify-center button" />
                                </div>
                            </div>
                        </div>
                        <div className={`module w-full overflow-x-hidden ${bmCollapsed ? 'collapsed' : ''}`} id="module-bookmarks">
                            {choosingBookmark && <div className="p-2 border-b">
                                <div className="flex justify-between"><span>Choose a local script</span><button onClick={() => setChoosingBookmark(false)}>Cancel</button></div>
                                <FilesystemTree searchQuery={searchQuery} onSelect={bookmarkFile} />
                            </div>}
                            <BookmarksList searchQuery={searchQuery} />
                        </div>

                        {/* Module 3: GitHub Gists */}
                        <div
                            className="module-caption group sticky top-0 z-10 flex items-center border-y p-0.5 cursor-pointer"
                            onClick={() => setGistsCollapsed(!gistsCollapsed)}
                        >
                            <iconify-icon
                                icon="heroicons:chevron-down"
                                class={`flex items-center justify-center chevron text-[0] opacity-50 transition-all hover:opacity-100 group-hover:text-base ${
                                    gistsCollapsed ? 'rotate-180' : 'rotate-0'
                                }`}
                            />
                            <div className="text text-base">
                                <div className="flex items-center gap-1 text-green-400">
                                    <iconify-icon icon="ci:github" class="flex items-center justify-center text-lg" />
                                    <span>GitHub Gists</span>
                                </div>
                            </div>
                            <div className="actions ml-auto mr-1 flex text-base">
                                <button title="Add GitHub Gist" onClick={e => { e.stopPropagation(); addGist(); }}><iconify-icon icon="fluent:add-20-filled" /></button>
                                <div className="active:opacity-50 cursor-pointer" title="Refresh Gists" onClick={(e) => { e.stopPropagation(); setGistRevision(value => value + 1); }}>
                                    <iconify-icon icon="fluent:arrow-clockwise-20-filled" class="flex items-center justify-center button" />
                                </div>
                            </div>
                        </div>
                        <div className={`module w-full overflow-x-hidden ${gistsCollapsed ? 'collapsed' : ''}`} id="module-gists">
                            <GistsList revision={gistRevision} />
                        </div>
                    </div>
                </div>
            </div>

            {/* Resize Handles */}
            <div>
                <div
                    id="resize-left"
                    style={{
                        position: 'absolute',
                        userSelect: 'none',
                        width: '10px',
                        height: '100%',
                        top: 0,
                        left: '-5px',
                        cursor: 'col-resize',
                        zIndex: 20
                    }}
                    onMouseDown={isLeftSidebar ? undefined : handleMouseDown}
                />
                <div
                    id="resize-right"
                    style={{
                        position: 'absolute',
                        userSelect: 'none',
                        width: '10px',
                        height: '100%',
                        top: 0,
                        right: '-5px',
                        cursor: 'col-resize',
                        zIndex: 20
                    }}
                    onMouseDown={isLeftSidebar ? handleMouseDown : undefined}
                />
            </div>
        </div>
    );
}
