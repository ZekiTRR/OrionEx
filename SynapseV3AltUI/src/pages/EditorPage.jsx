import React from 'react';
import { useApp } from '../context/AppContext';
import { EditorTabs } from '../components/editor/EditorTabs';
import { MonacoView } from '../components/editor/MonacoView';
import { ActionBar } from '../components/editor/ActionBar';
import { Sidebar } from '../components/sidebar/Sidebar';

export function EditorPage() {
    const { settings } = useApp();
    const isActionsOnTop = settings.editorstyle === '1';
    const isSidebarLeft = settings.sidebarlayout === '0';

    return (
        <div id="page-editor" className="editor-page flex h-full w-full overflow-hidden">
            {/* Sidebar Left */}
            {isSidebarLeft && <Sidebar />}

            {/* Editor Workspace */}
            <div className="editor-view flex flex-1 flex-col min-w-0 h-full overflow-hidden">
                {isActionsOnTop ? (
                    <>
                        <ActionBar />
                        <MonacoView />
                        <EditorTabs />
                    </>
                ) : (
                    <>
                        <EditorTabs />
                        <MonacoView />
                        <ActionBar />
                    </>
                )}
            </div>

            {/* Sidebar Right */}
            {!isSidebarLeft && <Sidebar />}
        </div>
    );
}
