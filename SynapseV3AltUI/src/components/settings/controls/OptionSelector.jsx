import React from 'react';

export function OptionSelector({ options, value, onChange, idPrefix }) {
    return (
        <div className="flex items-center rounded-md border p-0.5 select-none">
            {options.map((opt, index) => {
                const isSelected = String(value) === String(index);
                return (
                    <button
                        key={index}
                        id={idPrefix ? `optsel-${index}-${idPrefix}` : undefined}
                        className={`rounded px-2 py-0.5 text-xs lg:text-sm transition-colors cursor-pointer ${
                            isSelected
                                ? 'bg-white/20 text-white font-medium shadow-sm'
                                : 'opacity-60 hover:opacity-100 text-inherit'
                        }`}
                        onClick={(e) => {
                            e.stopPropagation();
                            onChange?.(index);
                        }}
                    >
                        <div>{opt}</div>
                    </button>
                );
            })}
        </div>
    );
}
