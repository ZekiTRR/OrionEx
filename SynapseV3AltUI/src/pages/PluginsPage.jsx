import React from 'react';
export function PluginsPage() {
    return <div id="page-plugins" className="page-container flex h-full w-full flex-col p-4">
        <div className="category-label flex items-center gap-2 p-2"><iconify-icon icon="fluent:puzzle-piece-20-filled" />Plugins</div>
        <div className="p-4" role="status">Unavailable in SynapseV3Alt. The original plugin section was incomplete; this UI-only port does not load or run third-party plugins.</div>
    </div>;
}
