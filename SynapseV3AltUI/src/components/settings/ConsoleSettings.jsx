import React from 'react';
import { useApp } from '../../context/AppContext';
import { i18n } from '../../services/i18nService';
import { SettingRow } from './controls/SettingRow';
import { Checkbox } from './controls/Checkbox';
import { Slider } from './controls/Slider';

export function ConsoleSettings() {
    const { settings, updateSetting } = useApp();

    return (
        <div id="settings-category-console" className="page">
            <div className="category-label sticky top-0 z-10 flex items-center gap-1 p-1 lg:gap-2 lg:p-2">
                <iconify-icon icon="fluent:window-console-20-filled" />
                <span data-i18n="settings-category-console">{i18n.t('settings-category-console', 'Console')}</span>
            </div>

            {/* 1. Log language server errors to output */}
            <SettingRow
                caption={i18n.t('settings-loglsp', 'Log language server errors to output')}
                description={i18n.t('settings-loglsp-desc', 'Mostly for UI developers that are toying with the LSP.')}
                onClick={() => updateSetting('log_lsp_errors', !settings.log_lsp_errors)}
            >
                <Checkbox
                    id="setting-log-lsp-errors"
                    checked={settings.log_lsp_errors}
                    onChange={(val) => updateSetting('log_lsp_errors', val)}
                />
            </SettingRow>

            {/* 2. Maximum log count for preservation */}
            <SettingRow
                caption={i18n.t('settings-maxlogcount', 'Maximum log count for preservation')}
                description={i18n.t('settings-maxlogcount-desc', 'Maximum amount of console messages to be preserved. Default: 720')}
            >
                <Slider
                    id="setting-max-log-count"
                    min={64}
                    max={8192}
                    value={settings.max_log_count}
                    onChange={(val) => updateSetting('max_log_count', val)}
                />
            </SettingRow>

            {/* 3. Show console at launch */}
            <SettingRow
                caption={i18n.t('settings-showconsolelaunch', 'Show console at launch')}
                description={i18n.t('settings-showconsolelaunch-desc', 'Whether the console will show up under the editor at launch.')}
                onClick={() => updateSetting('show_console_at_launch', !settings.show_console_at_launch)}
            >
                <Checkbox
                    id="setting-show-console-at-launch"
                    checked={settings.show_console_at_launch}
                    onChange={(val) => updateSetting('show_console_at_launch', val)}
                />
            </SettingRow>
        </div>
    );
}
