import React, { useState, useEffect } from 'react';
import { useEditor } from '../../context/EditorContext';
import { useApp } from '../../context/AppContext';
import { i18n } from '../../services/i18nService';

export function ActionBar() {
    const { activeTab, updateTabContent, saveActiveScript, openFileInEditor, monacoEditorRef } = useEditor();
    const { settings } = useApp();
    const [isConnected, setIsConnected] = useState(false);
    const [, setLangTick] = useState(0);

    useEffect(() => {
        return i18n.subscribe(() => setLangTick(t => t + 1));
    }, []);

    const handleExecute = () => {
        if (!activeTab) return;
        const code = activeTab.content || '';
        window.hwAPI?.execute?.(code);
    };

    const handleClear = async () => {
        if (!activeTab) return;
        const isDirty = (activeTab.content || '').trim().length > 0;
        const warnUnsaved = localStorage.getItem('synapse_setting_unsaved_warnings') !== 'false';

        if (warnUnsaved && isDirty && window.HWDialog?.confirmEraseUnsaved) {
            const confirmed = await window.HWDialog.confirmEraseUnsaved();
            if (!confirmed) return;
        }

        updateTabContent(activeTab.id, '');
        if (monacoEditorRef.current) {
            const model = monacoEditorRef.current.getModel();
            if (model) model.setValue('');
        }
    };

    const handleOpenFile = async () => {
        const file = await window.hwAPI?.openFileDialog?.();
        if (file && file.name) {
            openFileInEditor(file.name, file.content, { filePath: file.filePath || file.path, isFile: true });
        }
    };

    const handleExecuteFile = () => window.hwAPI.execute();

    const handleSaveFile = () => {
        saveActiveScript();
    };

    const handleOpenConsole = () => {
        window.hwAPI?.openConsole?.();
    };

    const handleOpenDocs = () => {
       window.HW.addMessage({
           header: i18n.t('tasks-header', 'Tasks'),
           desc: "No documentation yet.",
           state: 'failure',
           icon: 'fluent:warning-20-filled',
           autoDismiss: 4000,
        });
    };

    const isAlignLeft = String(settings.actionbar_direction) === '0';

    return (
        <div id="actions" className={`action-bar box-border flex h-12 w-full items-center border-t p-1 select-none ${isAlignLeft ? 'align-left' : ''}`}>
            {/* Status, Target & External Controls */}
            <div
                className="action-icons flex gap-1 px-1"
                style={isAlignLeft ? { order: 10, marginLeft: 'auto', marginRight: '0px' } : { order: 0, marginLeft: '0px', marginRight: '0px' }}
            >
                <div
                    className="connection-toggle group flex items-center justify-center text-xl cursor-pointer"
                    title="Connections are disabled."
                >
                    <iconify-icon
                        icon="fluent:plug-disconnected-20-filled"
                        class="flex items-center justify-center transition-opacity opacity-50 group-hover:opacity-100"
                    />
                    <iconify-icon
                        icon="svg-spinners:ring-resize"
                        class="flex items-center justify-center absolute opacity-0"
                    />
                </div>

                <div
                    id="console-icon"
                    className="group flex items-center justify-center cursor-pointer"
                    role="button"
                    tabIndex={0}
                    onClick={handleOpenConsole}
                >
                    <iconify-icon
                        icon="fluent:pulse-square-20-regular"
                        class="flex items-center justify-center action-button text-2xl transition opacity-50 group-hover:opacity-100 pointer-events-none"
                    />
                </div>

                <div
                    id="documentation-icon"
                    className="group flex items-center justify-center cursor-pointer"
                    role="button"
                    tabIndex={0}
                    onClick={handleOpenDocs}
                >
                    <iconify-icon
                        icon="fluent:search-square-20-regular"
                        class="flex items-center justify-center action-button text-2xl transition opacity-50 group-hover:opacity-100 pointer-events-none"
                    />
                </div>
            </div>

            {/* Action Buttons */}
            <div
                className="action-list flex items-center"
                style={isAlignLeft ? { order: 0, marginLeft: '0px', marginRight: 'auto' } : { order: 10, marginLeft: 'auto', marginRight: '0px' }}
            >
                {/* Execute */}
                <button
                    id="execute-button"
                    aria-disabled="true"
                    className={`hw-button relative flex select-none items-center justify-center rounded-md cursor-default ${
                        !isConnected ? 'opacity-50' : ''
                    }`}
                    onClick={handleExecute}
                    title="Execute"
                >
                    <iconify-icon icon="fluent:play-20-filled" class="flex items-center justify-center" />
                    <span className="btn-text">{i18n.t('button-execute', 'Execute')}</span>
                </button>

                {/* Clear */}
                <button
                    id="clear-button"
                    className="hw-button relative flex select-none items-center justify-center rounded-md cursor-default"
                    onClick={handleClear}
                    title="Clear"
                >
                    <iconify-icon icon="fluent:eraser-20-filled" class="flex items-center justify-center" />
                    <span className="btn-text">{i18n.t('button-clear', 'Clear')}</span>
                </button>

                {/* Open File */}
                <div>
                    <button
                        id="openf-button"
                        className="hw-button relative flex select-none items-center justify-center rounded-md cursor-default"
                        onClick={handleOpenFile}
                        title="Open File"
                    >
                        <iconify-icon icon="fluent:document-arrow-up-20-filled" class="flex items-center justify-center" />
                        <span className="btn-text">{i18n.t('button-open-file', 'Open')}</span>
                    </button>
                </div>

                {/* Execute File */}
                <button
                    id="executef-button"
                    aria-disabled="true"
                    className={`hw-button relative flex select-none items-center justify-center rounded-md cursor-default ${
                        !isConnected ? 'opacity-50' : ''
                    }`}
                    onClick={handleExecuteFile}
                    title="Execute File"
                >
                    <iconify-icon icon="fluent:settings-20-filled" class="flex items-center justify-center" />
                    <span className="btn-text">{i18n.t('button-execute-file', 'Execute')}</span>
                </button>

                {/* Save File */}
                <button
                    id="savef-button"
                    className="hw-button relative flex select-none items-center justify-center rounded-md cursor-default"
                    onClick={handleSaveFile}
                    title="Save File"
                >
                    <iconify-icon icon="fluent:save-20-filled" class="flex items-center justify-center" />
                    <span className="btn-text">{i18n.t('button-save-file', 'Save')}</span>
                </button>
            </div>
        </div>
    );
}
