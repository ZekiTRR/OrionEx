import React, { useEffect, useState } from 'react';
import { normalizeFontSize } from '../../services/editorFont';
import { useApp } from '../../context/AppContext';
import { i18n } from '../../services/i18nService';
import { SettingRow } from './controls/SettingRow';
import { Checkbox } from './controls/Checkbox';
import { Slider } from './controls/Slider';
import { Dropdown } from './controls/Dropdown';

export function EditorSettings() {
    const { settings, updateSetting } = useApp();
    const [defaultContent, setDefaultContent] = useState(settings.default_tab_content);
    const [systemFonts, setSystemFonts] = useState([]);
    const [fontSizeInput, setFontSizeInput] = useState(String(settings.fontsize ?? 16));

    useEffect(() => {
        let cancelled = false;
        window.hwAPI?.listSystemFonts?.().then((fonts) => {
            if (!cancelled && Array.isArray(fonts) && fonts.length) setSystemFonts(fonts);
        }).catch(() => {});
        return () => { cancelled = true; };
    }, []);

    useEffect(() => setFontSizeInput(String(settings.fontsize ?? 16)), [settings.fontsize]);

    const fontItems = [{ id: '', name: i18n.t('settings-ffamily-default', 'Default (Consolas)') },
        ...systemFonts.map(name => ({ id: name, name }))];

    const commitFontSize = () => updateSetting('fontsize', fontSizeInput);

    const handleSaveDefaultContent = () => {
        updateSetting('default_tab_content', defaultContent);
    };

    return (
        <div id="settings-category-editor" className="page">
            <div className="category-label sticky top-0 z-10 flex items-center gap-1 p-1 lg:gap-2 lg:p-2">
                <iconify-icon icon="fluent:code-20-filled" />
                <span data-i18n="settings-category-editor">{i18n.t('settings-category-editor', 'Editor')}</span>
            </div>

            {/* 1. Editor action bar position */}
            <SettingRow
                caption={i18n.t('settings-editorstyle', 'Editor action bar position')}
                description={i18n.t('settings-editorstyle-desc', 'Adjust the vertical position of the editor action bar and tabs.')}
            >
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        String(settings.editorstyle) === '0' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-0-editorstyle"
                    title="Actions on bottom, tabs on top"
                    onClick={() => updateSetting('editorstyle', '0')}
                >
                    <iconify-icon icon="fluent:panel-bottom-contract-20-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-editorstyle-bottom', 'Actions on bottom, tabs on top')}</div>
                </button>
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        String(settings.editorstyle) === '1' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-1-editorstyle"
                    title="Actions on top, tabs on bottom"
                    onClick={() => updateSetting('editorstyle', '1')}
                >
                    <iconify-icon icon="fluent:panel-top-contract-20-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-editorstyle-top', 'Actions on top, tabs on bottom')}</div>
                </button>
            </SettingRow>

            {/* 2. Action bar position */}
            <SettingRow
                caption={i18n.t('settings-actionbar-direction', 'Action bar position')}
                description={i18n.t('settings-actionbar-direction-desc', 'Adjust the vertical location of the actionbar.')}
            >
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        String(settings.actionbar_direction) === '0' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-0-actionbar-direction"
                    title="Align to left (Classic style)"
                    onClick={() => updateSetting('actionbar_direction', '0')}
                >
                    <iconify-icon icon="fluent:align-left-16-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-actionbar-left', 'Align to left (Classic style)')}</div>
                </button>
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        String(settings.actionbar_direction) === '1' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-1-actionbar-direction"
                    title="Align to right (Modern style)"
                    onClick={() => updateSetting('actionbar_direction', '1')}
                >
                    <iconify-icon icon="fluent:align-right-16-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-actionbar-right', 'Align to right (Modern style)')}</div>
                </button>
            </SettingRow>

            {/* 3. Compact editor buttons */}
            <SettingRow
                caption={i18n.t('settings-compactbtns', 'Compact editor buttons')}
                description={i18n.t('settings-compactbtns-desc', 'Reduces the size of the editor buttons.')}
                onClick={() => updateSetting('compact_btns', !settings.compact_btns)}
            >
                <Checkbox
                    id="setting-compact-btns"
                    checked={settings.compact_btns}
                    onChange={(val) => updateSetting('compact_btns', val)}
                />
            </SettingRow>

            {/* 4. Compact tabs */}
            <SettingRow
                caption={i18n.t('settings-squaretabs', 'Compact tabs')}
                description={i18n.t('settings-squaretabs-desc', 'Use compact square tabs instead of round padded ones.')}
                onClick={() => updateSetting('compact_tabs', !settings.compact_tabs)}
            >
                <Checkbox
                    id="setting-compact-tabs"
                    checked={settings.compact_tabs}
                    onChange={(val) => updateSetting('compact_tabs', val)}
                />
            </SettingRow>

            {/* 5. Default Tab Content */}
            <SettingRow
                caption={i18n.t('settings-newtabcontent', 'Default Tab Content')}
                description={i18n.t('settings-newtabcontent-desc', 'What will be written to the contents of a new tab.')}
            >
                <div id="newtabcontent" className="hw-textbox rounded-md px-2 py-1">
                    <div className="inner flex items-center gap-2 border px-1 py-0.5">
                        <input
                            className="w-full border-none bg-transparent text-inherit outline-none text-sm"
                            type="text"
                            placeholder="print('Synapse winning!')"
                            value={defaultContent}
                            onChange={(e) => setDefaultContent(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && handleSaveDefaultContent()}
                        />
                    </div>
                </div>
                <button
                    id="setting-default-tab-save-btn"
                    className="hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default"
                    onClick={handleSaveDefaultContent}
                >
                    <iconify-icon icon="fluent:save-20-filled" class="flex items-center justify-center" />
                    <span>{i18n.t('button-save-file', 'Save')}</span>
                </button>
            </SettingRow>

            {/* 6. Font Size */}
            <SettingRow
                caption={i18n.t('settings-fsize', 'Font Size')}
                description={i18n.t('settings-fsize-desc', 'Changes the size of the editor font.')}
            >
                <Slider
                    id="setting-font-size"
                    min={8}
                    max={48}
                    value={settings.fontsize}
                    onChange={(val) => updateSetting('fontsize', val)}
                />
                <input
                    id="setting-font-size-number"
                    className="hw-textbox w-20 rounded-md border px-2 py-1 text-sm"
                    type="number"
                    min={8}
                    max={48}
                    step={1}
                    value={fontSizeInput}
                    onChange={(e) => setFontSizeInput(e.target.value)}
                    onBlur={commitFontSize}
                    onKeyDown={(e) => {
                        if (e.key === 'Enter') { e.currentTarget.blur(); }
                        if (e.key === 'Escape') { e.currentTarget.value = ''; commitFontSize(e); }
                    }}
                />
            </SettingRow>

            {/* 6b. Editor Font Family */}
            <SettingRow
                caption={i18n.t('settings-ffamily', 'Editor Font')}
                description={i18n.t('settings-ffamily-desc', 'Font family for the script editor, from the fonts installed on this system.')}
            >
                <Dropdown
                    id="setting-font-family"
                    items={fontItems}
                    value={settings.fontfamily || ''}
                    onChange={(val) => updateSetting('fontfamily', val || '')}
                />
            </SettingRow>

            {/* 7. Tab Length */}
            <SettingRow
                caption={i18n.t('settings-tablength', 'Tab Length')}
                description={i18n.t('settings-tablength-desc', 'Changes the amount of tabs inserted for indentation.')}
            >
                <Slider
                    id="setting-tab-length"
                    min={1}
                    max={8}
                    value={settings.tab_length}
                    onChange={(val) => updateSetting('tab_length', val)}
                />
            </SettingRow>

            {/* 8. Minimap */}
            <SettingRow
                caption={i18n.t('settings-minimap', 'Minimap')}
                description={i18n.t('settings-minimap-desc', 'Configure the editor minimap.')}
            >
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        settings.minimap === 0 ? 'outline outline-2' : ''
                    }`}
                    id="optsel-0-minimap"
                    title="No minimap"
                    onClick={() => updateSetting('minimap', 0)}
                >
                    <iconify-icon icon="fluent:presence-blocked-16-regular" class="flex items-center justify-center" />
                    <div className="hidden lg:flex">{i18n.t('settings-minimap-disabled', 'No minimap')}</div>
                </button>
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        settings.minimap === 1 ? 'outline outline-2' : ''
                    }`}
                    id="optsel-1-minimap"
                    title="Minimap on right"
                    onClick={() => updateSetting('minimap', 1)}
                >
                    <iconify-icon icon="fluent:panel-right-contract-16-filled" class="flex items-center justify-center" />
                    <div className="hidden lg:flex">{i18n.t('settings-minimap-right', 'Minimap on right')}</div>
                </button>
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        settings.minimap === 2 ? 'outline outline-2' : ''
                    }`}
                    id="optsel-2-minimap"
                    title="Minimap on left"
                    onClick={() => updateSetting('minimap', 2)}
                >
                    <iconify-icon icon="fluent:panel-left-contract-16-filled" class="flex items-center justify-center" />
                    <div className="hidden lg:flex">{i18n.t('settings-minimap-left', 'Minimap on left')}</div>
                </button>
            </SettingRow>

            {/* 9. Lua language server */}
            <SettingRow
                caption={i18n.t('settings-lualsp', 'Lua language server')}
                description="Luau completions, hover and diagnostics from Orion's local language server. Toggling reloads the editor after saving the workspace."
                onClick={() => updateSetting('lua_language_server', !settings.lua_language_server)}
            >
                <Checkbox
                    id="setting-lua-language-server"
                    checked={settings.lua_language_server}
                    onChange={(val) => updateSetting('lua_language_server', val)}
                />
            </SettingRow>

            {/* 10. Smooth Cursor */}
            <SettingRow
                caption={i18n.t('settings-animcursor', 'Smooth Cursor')}
                description={i18n.t('settings-animcursor-desc', 'Enables smooth movement of the cursor.')}
                onClick={() => updateSetting('smooth_cursor', !settings.smooth_cursor)}
            >
                <Checkbox
                    id="setting-smooth-cursor"
                    checked={settings.smooth_cursor}
                    onChange={(val) => updateSetting('smooth_cursor', val)}
                />
            </SettingRow>

            {/* 11. Smooth Movement */}
            <SettingRow
                caption={i18n.t('settings-smoothscroll', 'Smooth Movement')}
                description={i18n.t('settings-smoothscroll-desc', 'Enables smooth scrolling in the editor.')}
                onClick={() => updateSetting('smooth_movement', !settings.smooth_movement)}
            >
                <Checkbox
                    id="setting-smooth-movement"
                    checked={settings.smooth_movement}
                    onChange={(val) => updateSetting('smooth_movement', val)}
                />
            </SettingRow>

            {/* 12. Show unsaved warnings */}
            <SettingRow
                caption={i18n.t('settings-unsavedwarn', 'Show unsaved warnings')}
                description={i18n.t('settings-unsavedwarn-desc', 'Warnings will be shown when trying to delete unsaved content.')}
                onClick={() => updateSetting('unsaved_warnings', !settings.unsaved_warnings)}
            >
                <Checkbox
                    id="setting-unsaved-warnings"
                    checked={settings.unsaved_warnings}
                    onChange={(val) => updateSetting('unsaved_warnings', val)}
                />
            </SettingRow>

            {/* 13. Word wrap */}
            <SettingRow
                caption={i18n.t('settings-wordwrap', 'Word wrap')}
                description={i18n.t('settings-wordwrap-desc', 'Wraps off-screen lines when enabled.')}
                onClick={() => updateSetting('word_wrap', !settings.word_wrap)}
            >
                <Checkbox
                    id="setting-word-wrap"
                    checked={settings.word_wrap}
                    onChange={(val) => updateSetting('word_wrap', val)}
                />
            </SettingRow>

            {/* 14. Sidebar position */}
            <SettingRow
                caption={i18n.t('settings-sidebarlayout', 'Sidebar position')}
                description={i18n.t('settings-sidebarlayout-desc', 'Adjust the horizontal location of the sidebar (file list).')}
            >
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        settings.sidebarlayout === '0' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-0-sidebarlayout"
                    title="Align to left"
                    onClick={() => updateSetting('sidebarlayout', '0')}
                >
                    <iconify-icon icon="fluent:align-left-16-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-sidebarlayout-left', 'Align to left')}</div>
                </button>
                <button
                    className={`hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-default ${
                        settings.sidebarlayout === '1' ? 'outline outline-2' : ''
                    }`}
                    id="optsel-1-sidebarlayout"
                    title="Align to right"
                    onClick={() => updateSetting('sidebarlayout', '1')}
                >
                    <iconify-icon icon="fluent:align-right-16-filled" />
                    <div className="hidden lg:flex">{i18n.t('settings-sidebarlayout-right', 'Align to right')}</div>
                </button>
            </SettingRow>
        </div>
    );
}
