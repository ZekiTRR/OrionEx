import React from 'react';
import { useApp } from '../../context/AppContext';
import { i18n } from '../../services/i18nService';

const NAV_ITEMS = [
    { id: 'editor', navKey: 'page-editor', defaultLabel: 'Editor', icon: 'fluent:window-console-20-filled', order: 0 },
    { id: 'settings', navKey: 'page-settings', defaultLabel: 'Settings', icon: 'fluent:settings-20-filled', order: 1 },
    { id: 'themes', navKey: 'page-customization', defaultLabel: 'Themes', icon: 'fluent:paint-brush-20-filled', order: 2 },
    { id: 'plugins', navKey: 'page-powertools', defaultLabel: 'Plugins', icon: 'fluent:puzzle-piece-20-filled', order: 3 },
];

export function NavigationBar() {
    const { activePage, setActivePage, settings, classicMenuOpen, setClassicMenuOpen } = useApp();

    const handleNavigate = (pageId) => {
        setActivePage(pageId);
        if (settings.classic_layout) {
            setClassicMenuOpen(false);
        }
    };

    return (
        <>
            {/* Classic layout backdrop blur */}
            {settings.classic_layout && (
                <div
                    id="classic-nav-backdrop"
                    className={classicMenuOpen ? 'open' : ''}
                    onClick={() => setClassicMenuOpen(false)}
                >
                    <div
                        className="classic-nav-blur-panel"
                        style={{
                            backdropFilter: 'blur(20px) saturate(140%)',
                            WebkitBackdropFilter: 'blur(20px) saturate(140%)',
                        }}
                    />
                </div>
            )}

            {/* Navigation Bar */}
            <div
                className={`hw-navigationbar select-none ${
                    settings.classic_layout && classicMenuOpen ? 'open' : ''
                }`}
            >
                {NAV_ITEMS.map((item) => {
                    const isSelected = activePage === item.id;
                    const label = i18n.t(item.navKey, item.defaultLabel);

                    return (
                        <div
                            key={item.id}
                            id={`nav-${item.id}`}
                            className={`entry group relative m-0.5 flex items-center justify-center rounded-md p-1 transition-colors cursor-pointer ${
                                isSelected ? 'select drop-shadow-md' : ''
                            }`}
                            style={{ order: item.order }}
                            onClick={() => handleNavigate(item.id)}
                        >
                            <iconify-icon
                                icon={item.icon}
                                class="flex items-center justify-center text-base"
                            />
                            <div className="label">
                                <iconify-icon icon={item.icon} class="flex items-center justify-center" />
                                <span>{label}</span>
                            </div>
                        </div>
                    );
                })}
            </div>
        </>
    );
}
