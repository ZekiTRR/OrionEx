import React, { useState, useRef } from 'react';
import { AppSettings } from '../components/settings/AppSettings';
import { EditorSettings } from '../components/settings/EditorSettings';
import { ConsoleSettings } from '../components/settings/ConsoleSettings';
import { InterfaceSettings } from '../components/settings/InterfaceSettings';
import { MiscSettings } from '../components/settings/MiscSettings';
import { i18n } from '../services/i18nService';

const CATEGORIES = [
    { id: 'appsettings', label: 'Application', icon: 'fluent:wrench-20-filled' },
    { id: 'settings-category-editor', label: 'Editor', icon: 'fluent:code-20-filled' },
    { id: 'settings-category-console', label: 'Console', icon: 'fluent:window-console-20-filled' },
    { id: 'settings-category-interface', label: 'Layout', icon: 'fluent:layer-diagonal-20-filled' },
    { id: 'settings-category-misc', label: 'Miscellaneous', icon: 'fluent:settings-20-filled' },
];

export function SettingsPage() {
    const [activeTab, setActiveTab] = useState('appsettings');
    const [searchFilter, setSearchFilter] = useState('');
    const pagesContainerRef = useRef(null);

    const scrollToCategory = (catId) => {
        setActiveTab(catId);
        const target = document.getElementById(catId);
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    };

    return (
        <div id="page-settings" className="page-container t-0 l-0 absolute flex h-full w-full flex-col overflow-y-auto">
            <div className="hw-multimenu flex h-full max-h-full w-full">
                {/* Categories Sidebar */}
                <div className="list z-10 flex flex-col border-r lg:w-1/5 select-none" id="settings-sidebar">
                    {CATEGORIES.map((cat) => {
                        const isSelected = activeTab === cat.id;
                        return (
                            <div
                                key={cat.id}
                                data-page={cat.id}
                                className={`entry group flex items-center transition-colors cursor-pointer ${
                                    isSelected ? 'select' : ''
                                }`}
                                onClick={() => scrollToCategory(cat.id)}
                            >
                                <iconify-icon
                                    icon={cat.icon}
                                    class={`flex items-center justify-center text-xl transition-opacity group-hover:opacity-100 ${
                                        isSelected ? 'opacity-100' : 'opacity-50 group-active:opacity-50'
                                    }`}
                                />
                                <div
                                    className={`caption hidden transition-opacity group-hover:opacity-100 lg:flex ${
                                        isSelected ? 'opacity-100' : 'opacity-50 group-active:opacity-50'
                                    }`}
                                >
                                    {i18n.t(cat.id, cat.label)}
                                </div>
                            </div>
                        );
                    })}
                </div>

                {/* Main Settings Area - Single continuous scroll list with all categories */}
                <div className="flex max-h-full grow flex-col">
                    {/* Search bar matching original without placeholder */}
                    <div className="hw-textbox rounded-md px-2 py-1">
                        <div className="inner flex items-center gap-2">
                            <iconify-icon icon="fluent:search-20-filled" class="flex items-center justify-center" />
                            <input
                                className="w-full border-none bg-transparent text-inherit outline-none"
                                type=""
                                value={searchFilter}
                                onChange={(e) => setSearchFilter(e.target.value)}
                            />
                        </div>
                    </div>

                    <div className="pages flex grow flex-col overflow-y-auto" id="settings-pages" ref={pagesContainerRef}>
                        <div id="appsettings" className="page">
                            <AppSettings />
                        </div>
                        <div id="settings-category-editor" className="page">
                            <EditorSettings />
                        </div>
                        <div id="settings-category-console" className="page">
                            <ConsoleSettings />
                        </div>
                        <div id="settings-category-interface" className="page">
                            <InterfaceSettings />
                        </div>
                        <div id="settings-category-misc" className="page">
                            <MiscSettings />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
