import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';

export function TitleBar() {
    const { settings, classicMenuOpen, setClassicMenuOpen } = useApp();
    const [isMaximized, setIsMaximized] = useState(false);

    useEffect(() => {
        const checkMax = () => {
            const max = window.hwAPI?.isMaximized?.();
            setIsMaximized(!!max);
        };
        checkMax();
        return window.hwAPI.onWindowState(checkMax);
    }, []);

    const handleMinimize = () => {
        window.hwAPI?.minimize?.();
    };

    const handleMaximize = () => {
        window.hwAPI?.maximize?.();

    };

    const handleClose = () => {
        window.hwAPI?.close?.();
    };

    const handleLanguageLink = () => {
        if (window.hwAPI?.openExternal) {
            window.hwAPI.openExternal('https://github.com/Okafor-twd/SynapseV3/');
        } else {
            window.open('https://github.com/Okafor-twd/SynapseV3/', '_blank');
        }
    };

    const handleToggleHamburger = (e) => {
        e.preventDefault();
        e.stopPropagation();
        setClassicMenuOpen(!classicMenuOpen);
    };

    return (
        <div className="hw-titlebar flex items-center w-full h-8 select-none" onPointerDown={e => { if (e.button === 0 && !e.target.closest('#controls')) window.hwAPI.startWindowDrag(); }} onDoubleClick={e => { if (!e.target.closest('#controls')) handleMaximize(); }}>
            <div id="titlebar-branding" className="flex h-2/3 pl-2">
                <div id="titlebar-logo" className="w-24 h-full bg-contain bg-no-repeat align-top" />
            </div>

            <div id="titlebar-middle-text" className="hidden mx-auto">
                SynapseV3Alt — UI-only
            </div>

            <div id="controls" className="flex ml-auto z-10">
                {/* Hamburger menu button for classic layout mode */}
                {settings.classic_layout && (
                    <div
                        id="ban_control_hamburger"
                        className="control p-2 cursor-pointer"
                        aria-label="Menu"
                        onClick={handleToggleHamburger}
                    >
                        <iconify-icon icon="fluent:list-16-regular" />
                    </div>
                )}

                {/* External repository link button */}
                <div
                    id="ban_control_language"
                    className="control p-2 cursor-pointer"
                    aria-label="Language & Repository"
                    onClick={handleLanguageLink}
                >
                    <iconify-icon icon="fluent:globe-16-regular" />
                </div>

                {/* Minimize */}
                <div
                    id="ban_control_minimize"
                    className="control p-2 cursor-pointer"
                    aria-label="Minimize"
                    onClick={handleMinimize}
                >
                    <iconify-icon icon="fluent:subtract-16-regular" />
                </div>

                {/* Maximize / Restore */}
                <div
                    id="ban_control_maximize"
                    className="control p-2 cursor-pointer"
                    aria-label={isMaximized ? "Restore" : "Maximize"}
                    onClick={handleMaximize}
                >
                    <iconify-icon icon={isMaximized ? "fluent:restore-16-regular" : "fluent:maximize-16-regular"} />
                </div>

                {/* Close */}
                <div
                    id="ban_control_close"
                    className="control p-2 cursor-pointer hover:bg-red-600 active:bg-red-700"
                    aria-label="Close"
                    onClick={handleClose}
                >
                    <iconify-icon icon="fluent:dismiss-16-regular" />
                </div>
            </div>
        </div>
    );
}
