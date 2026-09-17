import React, { useState, useEffect } from 'react';
import { useEditor } from '../../context/EditorContext';
import { themeService } from '../../services/themeService';

export function BookmarksList({ searchQuery = '' }) {
    const { openFileInEditor } = useEditor();
    const [bookmarks, setBookmarks] = useState([]);
    useEffect(() => {
        const load = async () => setBookmarks(await window.hwAPI.getSetting('bookmarks', []) || []);
        load();
        return window.hwAPI.onSettingsChanged(load);
    }, []);

    const open = async item => {
        if (!item.path) { window.HWToast?.info('This old URL bookmark is not a local script. Remove it and add a file from Local Filesystem.'); return; }
        const file = await window.hwAPI.readScript(item.path);
        if (typeof file?.content !== 'string') return;
        openFileInEditor(item.name || file.name, file.content, { isFile: true, filePath: item.path, isBookmark: true });
    };
    const remove = async item => {
        const next = bookmarks.filter(entry => entry !== item);
        if (await window.hwAPI.setSetting('bookmarks', next)) setBookmarks(next);
    };
    const q = searchQuery.trim().toLowerCase();
    return bookmarks.filter(item => `${item.name || ''} ${item.path || item.uri || ''}`.toLowerCase().includes(q)).map((item, index) => (
        <div className="node" key={item.path || index}>
            <div className="node-caption group flex items-center gap-1 py-0.5 pl-1 opacity-70 hover:opacity-100">
                <button className="flex min-w-0 flex-1 items-center text-left" title={item.path || 'Legacy URL bookmark — choose a local file instead'} onClick={() => open(item)}>
                    <iconify-icon icon={themeService.getThemeIcon('file', 'fluent:document-20-filled')} class="w-4 min-w-[1rem]" />
                    <span className="ml-2 truncate">{item.name || 'Bookmark'}</span>
                </button>
                <button title="Remove bookmark (keep file)" onClick={() => remove(item)}><iconify-icon icon="fluent:delete-20-filled" /></button>
            </div>
        </div>
    ));
}
