import React, { useState, useEffect } from 'react';
import { themeService } from '../services/themeService';
import { i18n } from '../services/i18nService';
import { SettingRow } from '../components/settings/controls/SettingRow';
import { Dropdown } from '../components/settings/controls/Dropdown';
import { useApp } from '../context/AppContext';

export function ThemesPage() {
    const { updateSetting, addProgressTask } = useApp();
    const [themesList, setThemesList] = useState(() => themeService.getThemesList());
    const [currentTheme, setCurrentTheme] = useState(() => themeService.getCurrentTheme());

    useEffect(() => {
        return themeService.subscribe((theme) => {
            setCurrentTheme(theme);
            setThemesList(themeService.getThemesList());
        });
    }, []);

    const handleSelectTheme = async (themeId) => {
        const meta = themeService.themeMetas[themeId] || themesList.find(t => t.id === themeId);
        if (meta && meta.settingOverrides) {
            let confirmed = false;
            if (window.HWDialog && typeof window.HWDialog.confirmThemeOverrides === 'function') {
                confirmed = await window.HWDialog.confirmThemeOverrides();
            }
            if (confirmed) {
                if (meta.settingOverrides.classiclayout !== undefined) {
                    updateSetting('classic_layout', meta.settingOverrides.classiclayout);
                }
                if (meta.settingOverrides.squaretabs !== undefined) {
                    updateSetting('compact_tabs', meta.settingOverrides.squaretabs);
                }
                if (meta.settingOverrides['actionbar-direction'] !== undefined) {
                    updateSetting('actionbar_direction', String(meta.settingOverrides['actionbar-direction']));
                }
                if (meta.settingOverrides.navbarstyle !== undefined) {
                    updateSetting('navbarstyle', String(meta.settingOverrides.navbarstyle));
                }
            }
        }
        themeService.loadTheme(themeId);
    };

    const handleOpenThemeDir = () => {
        window.hwAPI?.openThemeFolder?.();
    };

    const handleResetLayout = () => {
        updateSetting('classic_layout', false);
        updateSetting('navbarstyle', '0');
        updateSetting('editorstyle', '0');
        updateSetting('actionbar_direction', '1');
        updateSetting('sidebarlayout', '1');
        updateSetting('compact_tabs', false);
        updateSetting('compact_btns', false);

        if (window.HW && typeof window.HW.addMessage === 'function') {
            window.HW.addMessage({
                header: i18n.t('tasks-header', 'Tasks'),
                desc: i18n.t('theme-reset-feedback', 'Layout settings were reset to Modern style.'),
                state: 'complete',
                icon: 'fluent:checkmark-20-filled'
            });
        } else if (addProgressTask) {
            addProgressTask({
                header: i18n.t('tasks-header', 'Tasks'),
                desc: i18n.t('theme-reset-feedback', 'Layout settings were reset to Modern style.'),
                state: 'complete',
                icon: 'fluent:checkmark-20-filled'
            });
        }
    };

    return (
        <div id="page-themes" className="page-container flex h-full w-full flex-col overflow-y-auto">
            <div className="hw-multimenu flex h-full max-h-full w-full">
                {/* Themes Category Sidebar */}
                <div className="list z-10 flex flex-col border-r lg:w-1/5 select-none">
                    <div className="entry group flex items-center transition-colors cursor-pointer select">
                        <iconify-icon
                            icon="heroicons:wrench-solid"
                            class="flex items-center justify-center text-xl opacity-100"
                        />
                        <div className="caption hidden transition-opacity lg:flex opacity-100 font-semibold">
                            {i18n.t('engine-general', 'General')}
                        </div>
                    </div>
                </div>

                {/* Themes Content */}
                <div className="flex max-h-full grow flex-col">
                    <div className="pages flex grow flex-col overflow-y-auto">
                        <div className="page">
                            <div className="category-label sticky top-0 z-10 flex items-center gap-1 p-1 lg:gap-2 lg:p-2">
                                <iconify-icon icon="heroicons:wrench-solid" />
                                <span>{i18n.t('engine-general', 'General')}</span>
                            </div>

                            {/* Theme Selector Dropdown */}
                            <SettingRow
                                caption={i18n.t('theme-page-list', 'Available themes')}
                                description={i18n.t('theme-page-list-desc', 'Choose from prebuilt themes or custom community themes.')}
                            >
                                <Dropdown
                                    items={themesList}
                                    value={currentTheme.id}
                                    onChange={handleSelectTheme}
                                    placeholder="Select Theme..."
                                />
                            </SettingRow>

                            {/* Theme Directory Button */}
                            <SettingRow
                                caption={i18n.t('theme-directory-caption', 'Theme directory')}
                                description={i18n.t('theme-directory-desc', 'Open the local themes folder to install or customize stylesheets.')}
                            >
                                <button
                                    id="btn-open-theme-dir"
                                    className="hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-pointer hover:bg-white/10"
                                    onClick={handleOpenThemeDir}
                                >
                                    {i18n.t('button-open-file', 'Open')}
                                </button>
                            </SettingRow>

                            {/* Reset Layout */}
                            <SettingRow
                                caption={i18n.t('theme-reset-caption', 'Reset layout')}
                                description={i18n.t('theme-reset-desc', 'Restores default position, padding, and alignments for the Modern layout.')}
                            >
                                <button
                                    id="btn-reset-layout"
                                    className="hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-pointer hover:bg-white/10"
                                    onClick={handleResetLayout}
                                >
                                    {i18n.t('settings-reset-short', 'Reset')}
                                </button>
                            </SettingRow>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
