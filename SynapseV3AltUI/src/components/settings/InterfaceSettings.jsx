import React from 'react';
import { useApp } from '../../context/AppContext';
import { i18n } from '../../services/i18nService';
import { SettingRow } from './controls/SettingRow';
import { Checkbox } from './controls/Checkbox';
import { Slider } from './controls/Slider';

export function InterfaceSettings() {
    const { settings, updateSetting } = useApp();

    return (
        <div id="settings-category-interface" className="page">
            <div className="category-label sticky top-0 z-10 flex items-center gap-1 p-1 lg:gap-2 lg:p-2">
                <iconify-icon icon="fluent:layer-diagonal-20-filled" />
                <span data-i18n="settings-category-interface">{i18n.t('settings-category-interface', 'Layout')}</span>
            </div>

            {/* 1. Always on top */}
            <SettingRow
                caption={i18n.t('settings-topmost', 'Always on top')}
                description={i18n.t('settings-topmost-desc', 'Forces the interface to render on top of all windows.')}
                onClick={() => updateSetting('always_on_top', !settings.always_on_top)}
            >
                <Checkbox
                    id="setting-always-on-top"
                    checked={settings.always_on_top}
                    onChange={(val) => updateSetting('always_on_top', val)}
                />
            </SettingRow>

            {/* 2. Interface Scale */}
            <SettingRow
                caption={i18n.t('settings-scale', 'Interface Scale')}
                description={i18n.t('settings-scale-desc', 'Sets the zoom level of the UI.')}
            >
                <Slider
                    id="setting-interface-scale"
                    min={25}
                    max={150}
                    value={settings.interface_scale}
                    onChange={(val) => updateSetting('interface_scale', val)}
                />
            </SettingRow>

            {/* 3. Toast notification scale */}
            <SettingRow
                caption={i18n.t('settings-toastscale', 'Toast notification scale')}
                description={i18n.t('settings-toastscale-desc', 'Adjust the scale and size of toast and progress cards.')}
            >
                <Slider
                    id="setting-toast-scale"
                    min={50}
                    max={150}
                    value={settings.toast_scale}
                    onChange={(val) => updateSetting('toast_scale', val)}
                />
            </SettingRow>

            {/* 4. Navigation bar layout */}
            <SettingRow
                caption={i18n.t('settings-navbarstyle', 'Navigation bar layout')}
                description={i18n.t('settings-navbarstyle-desc', 'Adjust the layout and positioning of the navigation bar.')}
            >
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        settings.navbarstyle === '0' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-0-navbarstyle"
                    title="Align to top"
                    onClick={() => updateSetting('navbarstyle', '0')}
                >
                    <iconify-icon icon="fluent:panel-top-contract-20-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-navbarstyle-top', 'Align to top')}</div>
                </button>
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        settings.navbarstyle === '1' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-1-navbarstyle"
                    title="Align to left"
                    onClick={() => updateSetting('navbarstyle', '1')}
                >
                    <iconify-icon icon="fluent:panel-left-contract-20-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-navbarstyle-left', 'Align to left')}</div>
                </button>
            </SettingRow>

            {/* 5. Classic layout mode */}
            <SettingRow
                caption={i18n.t('settings-classiclayout', 'Classic layout mode')}
                description={i18n.t('settings-classiclayout-desc', 'Emulates the classic editor layout from yesteryear.')}
                onClick={() => updateSetting('classic_layout', !settings.classic_layout)}
            >
                <Checkbox
                    id="setting-classic-layout"
                    checked={settings.classic_layout}
                    onChange={(val) => updateSetting('classic_layout', val)}
                />
            </SettingRow>

            {/* 6. Animate collapse */}
            <SettingRow
                caption={i18n.t('settings-animatecollapse', 'Animate collapse')}
                description={i18n.t('settings-animatecollapse-desc', 'Smoothly animates collapsing and expanding sidebar modules and folders.')}
                onClick={() => updateSetting('animate_collapse', !settings.animate_collapse)}
            >
                <Checkbox
                    id="setting-animate-collapse"
                    checked={settings.animate_collapse}
                    onChange={(val) => updateSetting('animate_collapse', val)}
                />
            </SettingRow>

            {/* 7. Transparent window */}
            <SettingRow
                caption={i18n.t('settings-windowtransparency', 'Transparent window')}
                description={i18n.t('settings-windowtransparency-desc', 'Use a different rendering mode for theme transparency effects. Applies on reboot.')}
                onClick={() => updateSetting('transparent_window', !settings.transparent_window)}
            >
                <Checkbox
                    id="setting-transparent-window"
                    checked={settings.transparent_window}
                    onChange={(val) => updateSetting('transparent_window', val)}
                />
            </SettingRow>
        </div>
    );
}
