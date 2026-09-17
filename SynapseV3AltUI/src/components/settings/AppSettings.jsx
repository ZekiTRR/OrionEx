import React from 'react';
import { useApp } from '../../context/AppContext';
import { i18n, LANGUAGES } from '../../services/i18nService';
import { SettingRow } from './controls/SettingRow';
import { Dropdown } from './controls/Dropdown';
const changelogFallback = 'SynapseV3Alt — local UI-only port. Execution and remote services are unavailable.';

export function AppSettings() {
    const { settings, updateSetting, resetAllSettings, spawnDialog } = useApp();

    const handleShowChangelog = async () => {
        let content = changelogFallback;
        if (window.hwAPI?.getChangelog) {
            try {
                const live = await window.hwAPI.getChangelog();
                if (live && live.trim()) content = live;
            } catch (_) {}
        }

        spawnDialog({
            type: 'changelog',
            icon: 'fluent:news-20-filled',
            title: 'Changelog',
            body: content,
            buttons: ['Ok']
        });
    };

    return (
        <div id="appsettings" className="page">
            <div className="category-label sticky top-0 z-10 flex items-center gap-1 p-1 lg:gap-2 lg:p-2">
                <iconify-icon icon="fluent:wrench-20-filled" />
                <span data-i18n="settings-appcategory">{i18n.t('settings-appcategory', 'Application')}</span>
            </div>

            {/* 1. UI Language */}
            <SettingRow
                caption={i18n.t('settings-uilanguage', 'UI Language')}
                description={i18n.t('settings-uilanguage-desc', 'Choose your interface language.')}
            >
                <Dropdown
                    id="setting-ui-language-dropdown"
                    items={LANGUAGES}
                    value={settings.language}
                    onChange={(val) => updateSetting('language', val)}
                />
            </SettingRow>

            {/* 2. Reset All Settings */}
            <SettingRow
                caption={i18n.t('settings-reset', 'Reset all settings')}
                description="Reset appearance and editor settings. Open tabs, workspace and bookmarks are preserved."
            >
                <button
                    id="btn-reset-all-settings"
                    className="hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default"
                    onClick={resetAllSettings}
                >
                    {i18n.t('settings-reset-short', 'Reset')}
                </button>
            </SettingRow>

            {/* 3. Show Changelog */}
            <SettingRow
                caption={i18n.t('settings-changelog', 'Show changelog')}
                description={i18n.t('settings-changelog-desc', 'Clicking this will show you the changelog for the latest version.')}
            >
                <button
                    id="btn-show-changelog"
                    className="hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default"
                    onClick={handleShowChangelog}
                >
                    {i18n.t('settings-changelog-short', 'Show')}
                </button>
            </SettingRow>
        </div>
    );
}
