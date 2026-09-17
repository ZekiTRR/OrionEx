import React from 'react';

export function SettingRow({ caption, description, children, onClick }) {
    return (
        <div
            className="action-container flex w-full items-center px-2 py-1 lg:px-3 lg:py-2"
            onClick={onClick}
        >
            <div className="text flex flex-col">
                <div className="caption text-xs lg:text-base">{caption}</div>
                {description && (
                    <div className="description text-xs opacity-50">{description}</div>
                )}
            </div>
            <div className="ml-auto flex gap-1 lg:gap-4">
                {children}
            </div>
        </div>
    );
}
