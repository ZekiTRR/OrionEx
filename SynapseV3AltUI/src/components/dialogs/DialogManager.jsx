import React, { useState, useEffect, useRef } from 'react';
import { useApp } from '../../context/AppContext';
import { i18n } from '../../services/i18nService';

const ACCENT_COLORS = [
    { name: 'Default (White)', hex: '' },
    { name: 'Red', hex: '#ef4444' },
    { name: 'Orange', hex: '#f97316' },
    { name: 'Amber', hex: '#f59e0b' },
    { name: 'Yellow', hex: '#eab308' },
    { name: 'Lime', hex: '#84cc16' },
    { name: 'Green', hex: '#22c55e' },
    { name: 'Emerald', hex: '#10b981' },
    { name: 'Teal', hex: '#14b8a6' },
    { name: 'Cyan', hex: '#06b6d4' },
    { name: 'Sky', hex: '#0ea5e9' },
    { name: 'Blue', hex: '#3b82f6' },
    { name: 'Indigo', hex: '#6366f1' },
    { name: 'Purple', hex: '#8b5cf6' },
    { name: 'Violet', hex: '#a855f7' },
    { name: 'Fuchsia', hex: '#d946ef' },
    { name: 'Pink', hex: '#ec4899' },
    { name: 'Rose', hex: '#f43f5e' }
];

export function DialogManager() {
    const { activeDialog } = useApp();
    const [inputValue, setInputValue] = useState('');
    const [closing, setClosing] = useState(false);
    const inputRef = useRef(null);

    useEffect(() => {
        if (activeDialog && activeDialog.textbox !== undefined) {
            setInputValue(activeDialog.textbox || '');
            setTimeout(() => {
                if (inputRef.current) {
                    inputRef.current.focus();
                    inputRef.current.select();
                }
            }, 120);
        } else {
            setInputValue('');
        }
        setClosing(false);
    }, [activeDialog]);

    if (!activeDialog) return null;

    const finish = (index, overrideValue = null) => {
        setClosing(true);
        setTimeout(() => {
            activeDialog.onClose?.(index, overrideValue !== null ? overrideValue : inputValue);
            setClosing(false);
        }, 100);
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            finish(0);
        } else if (e.key === 'Escape') {
            e.preventDefault();
            finish(1);
        }
    };

    const isAccentPicker = activeDialog.type === 'accent-picker';
    const isChangelog = activeDialog.type === 'changelog' || activeDialog.title?.toLowerCase() === 'changelog';
    const dialogIcon = isAccentPicker ? 'fluent:color-20-filled' : activeDialog.icon;
    const dialogIconColor = isAccentPicker ? 'white' : activeDialog.iconColor;

    return (
        <div id="canvas-dialog" className="canvas-overlay" style={{ pointerEvents: 'auto' }}>
            {/* Backdrop: 50% opacity dark overlay across the whole window */}
            <div
                className="flex h-full w-full select-none items-center justify-center transition-opacity pointer-events-auto bg-black/50 backdrop-blur-sm"
                style={{
                    opacity: closing ? 0 : 1,
                    transition: 'opacity 100ms ease-in'
                }}
                onMouseDown={(e) => {
                    if (e.target === e.currentTarget) finish(-1);
                }}
            >
                <div
                    className={`hw-dialog flex ${isChangelog ? 'min-w-[28rem] max-w-[38rem] w-[38rem] hw-changelog' : 'min-w-[24rem] max-w-[28rem]'} flex-col rounded-lg`}
                    style={{
                        animation: closing
                            ? '100ms ease-in 0s 1 normal forwards running elem-blur-out'
                            : '100ms ease-out 0s 1 normal forwards running elem-blur-in'
                    }}
                    onClick={(e) => e.stopPropagation()}
                >
                    {/* Content row */}
                    <div className="flex grow gap-4 p-4 min-w-0">
                        {dialogIcon && (
                            <iconify-icon
                                icon={dialogIcon}
                                class="flex items-center justify-center translate-y-1 text-2xl flex-shrink-0"
                                style={dialogIconColor ? { color: dialogIconColor } : undefined}
                            />
                        )}
                        <div className="flex h-full flex-col gap-2 flex-grow min-w-0">
                            <div className="caption align-top text-xl font-bold">{activeDialog.title}</div>
                            {activeDialog.body && (
                                <div className={`text-sm opacity-90 whitespace-pre-wrap ${isChangelog ? 'changelog-contents max-h-[55vh] overflow-y-auto pr-2 select-text font-sans leading-relaxed' : ''}`}>
                                    {activeDialog.body}
                                </div>
                            )}

                            {/* Accent Color Palette Picker - exactly like original Hollywood UI */}
                            {isAccentPicker && (
                                <div
                                    className="flex flex-wrap gap-1.5 pt-1"
                                    style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', maxWidth: '20rem' }}
                                >
                                    {ACCENT_COLORS.map((item) => (
                                        <div
                                            key={item.hex}
                                            className="rounded-full cursor-pointer hover:brightness-150 active:opacity-50 transition-transform hover:scale-110"
                                            style={{
                                                width: '1.25rem',
                                                height: '1.25rem',
                                                borderRadius: '9999px',
                                                backgroundColor: item.hex || '#ffffff',
                                                border: item.hex === '' || item.hex === '#ffffff' ? '1px solid rgba(255,255,255,0.5)' : 'none',
                                                flexShrink: 0
                                            }}
                                            data-color={item.hex}
                                            title={item.name}
                                            onClick={() => finish(0, item.hex)}
                                        />
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Optional Textbox */}
                    {activeDialog.textbox !== undefined && (
                        <div className="mx-2 mb-2">
                            <div className="hw-textbox rounded-md px-2 py-1">
                                <div className="inner flex items-center gap-2 border px-1 py-0.5">
                                    <input
                                        ref={inputRef}
                                        type="text"
                                        value={inputValue}
                                        onChange={(e) => setInputValue(e.target.value)}
                                        onKeyDown={handleKeyDown}
                                        className="w-full border-none bg-transparent text-inherit outline-none text-sm"
                                    />
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Buttons row */}
                    <div className="inputs flex h-16 w-full rounded-b-lg border-t px-2 py-4">
                        <div className="ml-auto flex gap-2">
                            {activeDialog.buttons?.map((label, index) => {
                                let translatedLabel = label;
                                if (typeof window.i18n?.t === 'function') {
                                    const normKey = 'dialog-' + String(label).trim().toLowerCase();
                                    translatedLabel = window.i18n.t(normKey, label);
                                }
                                return (
                                    <button
                                        key={index}
                                        className="hw-button relative flex select-none items-center justify-center gap-1 rounded-md px-2 py-1 cursor-pointer"
                                        onClick={() => finish(index)}
                                    >
                                        {translatedLabel}
                                    </button>
                                );
                            })}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
