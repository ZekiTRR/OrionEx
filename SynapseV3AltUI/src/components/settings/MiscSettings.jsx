import React from 'react';
import { i18n } from '../../services/i18nService';

export function MiscSettings() {
    return (
        <div id="settings-category-misc" className="page">
            <div className="category-label sticky top-0 z-10 flex items-center gap-1 p-1 lg:gap-2 lg:p-2">
                <iconify-icon icon="fluent:settings-20-filled" />
                <span data-i18n="settings-category-misc">{i18n.t('settings-category-misc', 'Miscellaneous')}</span>
            </div>
            <div className="flex w-full items-center justify-center p-6 text-xs lg:text-sm opacity-40 select-none">
                (No options here for now!)
            </div>
        </div>
    );
}
