import React from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { EditorProvider } from './context/EditorContext';
import { TitleBar } from './components/layout/TitleBar';
import { NavigationBar } from './components/layout/NavigationBar';
import { GatewayScreen } from './components/layout/GatewayScreen';
import { EditorPage } from './pages/EditorPage';
import { SettingsPage } from './pages/SettingsPage';
import { ThemesPage } from './pages/ThemesPage';
import { PluginsPage } from './pages/PluginsPage';
import { DialogManager } from './components/dialogs/DialogManager';
import { ToastContainer } from './components/toasts/ToastContainer';
import { ProgressView } from './components/toasts/ProgressView';

function MainLayout() {
    const { activePage } = useApp();

    return (
        <div id="application" className="rounded-lg flex flex-col w-screen h-screen overflow-hidden select-none">
            {/* Gateway Bootscreen */}
            <GatewayScreen />

            {/* Title Bar */}
            <TitleBar />

            {/* Navigation Bar */}
            <NavigationBar />

            {/* Content Area */}
            <div id="content-area" className="relative flex-1 min-h-0 w-full overflow-hidden">
                <div className="w-full relative h-full">
                    <div className={`page-container t-0 l-0 absolute flex h-full w-full flex-col overflow-y-auto ${activePage === 'editor' ? 'pointer-events-auto opacity-100 visible-page' : 'pointer-events-none opacity-0 hidden-page'}`}>
                        <EditorPage />
                    </div>
                    <div className={`page-container t-0 l-0 absolute flex h-full w-full flex-col overflow-y-auto ${activePage === 'settings' ? 'pointer-events-auto opacity-100 visible-page' : 'pointer-events-none opacity-0 hidden-page'}`}>
                        <SettingsPage />
                    </div>
                    <div className={`page-container t-0 l-0 absolute flex h-full w-full flex-col overflow-y-auto ${activePage === 'themes' ? 'pointer-events-auto opacity-100 visible-page' : 'pointer-events-none opacity-0 hidden-page'}`}>
                        <ThemesPage />
                    </div>
                    <div className={`page-container t-0 l-0 absolute flex h-full w-full flex-col overflow-y-auto ${activePage === 'plugins' ? 'pointer-events-auto opacity-100 visible-page' : 'pointer-events-none opacity-0 hidden-page'}`}>
                        <PluginsPage />
                    </div>
                </div>
            </div>

            {/* Dynamic Overlays */}
            <ProgressView />
            <DialogManager />
            <ToastContainer />
            <div id="canvas-menus" className="canvas-overlay l-0 absolute top-0 z-[250] flex h-full w-full opacity-100 pointer-events-none overflow-x-hidden" />
        </div>
    );
}

export function App() {
    return (
        <AppProvider>
            <EditorProvider>
                <MainLayout />
            </EditorProvider>
        </AppProvider>
    );
}

export default App;
