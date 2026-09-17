import React, { useState, useRef, useEffect } from 'react';

export function Dropdown({ items, value, onChange, placeholder = 'Select...' }) {
    const [open, setOpen] = useState(false);
    const ref = useRef(null);

    useEffect(() => {
        const handleClickOutside = (e) => {
            if (ref.current && !ref.current.contains(e.target)) {
                setOpen(false);
            }
        };
        document.addEventListener('click', handleClickOutside);
        return () => document.removeEventListener('click', handleClickOutside);
    }, []);

    const selectedItem = items.find(i => String(i.id) === String(value));
    const label = selectedItem ? selectedItem.name : placeholder;

    return (
        <div className={`hw-dropdown min-w-[12rem] relative flex flex-col ${open ? 'open' : ''}`} ref={ref}>
            <div
                className="selector flex items-center rounded-md px-2 py-1 border cursor-pointer select-none"
                onClick={(e) => {
                    e.stopPropagation();
                    setOpen(!open);
                }}
            >
                <div className="dropdown-entry p-1 truncate">{label}</div>
                <iconify-icon
                    icon="heroicons:chevron-down"
                    class={`flex items-center justify-center ml-auto transition-transform ${open ? 'rotate-180' : ''}`}
                />
            </div>
            <div className={`list z-50 flex-col absolute top-[calc(100%_+_0.5rem)] max-h-[50vh] overflow-y-auto w-full rounded-md border ${open ? 'flex' : 'hidden'}`}>
                {items.map((item) => {
                    const isSelected = String(item.id) === String(value);
                    return (
                        <div
                            key={item.id}
                            className={`cursor-pointer opacity-70 active:opacity-50 hover:opacity-100 ${isSelected ? 'highlight' : ''}`}
                            onClick={(e) => {
                                e.stopPropagation();
                                onChange?.(item.id);
                                setOpen(false);
                            }}
                        >
                            <div className="dropdown-entry p-1">{item.name}</div>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
