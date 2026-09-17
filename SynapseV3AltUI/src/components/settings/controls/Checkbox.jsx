import React from 'react';

export function Checkbox({ checked, onChange, id }) {
    return (
        <div
            id={id}
            className={`hw-checkbox relative inline-flex items-center h-6 w-11 flex-shrink-0 rounded-full cursor-pointer border transition-colors duration-200 ease-in-out ${checked ? 'on' : ''}`}
            onClick={(e) => {
                e.stopPropagation();
                onChange?.(!checked);
            }}
            role="checkbox"
            aria-checked={checked}
        >
            <div
                className={`icon pointer-events-none relative inline-block rounded-full h-4 w-4 bg-white shadow transition-all duration-200 ease-in-out ${checked ? 'translate-x-5' : 'translate-x-1'}`}
            />
        </div>
    );
}
