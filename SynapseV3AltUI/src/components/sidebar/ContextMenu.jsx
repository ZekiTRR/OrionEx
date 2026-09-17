import React, { useEffect, useRef } from 'react';

export function ContextMenu({ x, y, items, onClose }) {
    const menuRef = useRef(null);

    useEffect(() => {
        const handleClick = (e) => {
            if (menuRef.current && !menuRef.current.contains(e.target)) {
                onClose?.();
            }
        };
        const handleKeyDown = (e) => {
            if (e.key === 'Escape') onClose?.();
        };

        document.addEventListener('click', handleClick);
        document.addEventListener('contextmenu', handleClick);
        document.addEventListener('keydown', handleKeyDown);

        return () => {
            document.removeEventListener('click', handleClick);
            document.removeEventListener('contextmenu', handleClick);
            document.removeEventListener('keydown', handleKeyDown);
        };
    }, [onClose]);

    // Bounds checking
    const adjustedX = Math.min(x, window.innerWidth - 200);
    const adjustedY = Math.min(y, window.innerHeight - (items.length * 30 + 20));

    return (
        <div
            ref={menuRef}
            className="hw-contextmenu fixed z-50 select-none shadow-2xl"
            style={{ left: adjustedX, top: adjustedY }}
            onClick={(e) => e.stopPropagation()}
        >
            {items.map((item, idx) => {
                if (item.separator) {
                    return <div key={idx} className="my-1 border-t border-white/10" />;
                }
                return (
                    <div
                        key={idx}
                        className="entry flex items-center gap-2 px-2 py-1 cursor-pointer hover:bg-white/10 rounded"
                        onClick={() => {
                            item.onClick?.();
                            onClose?.();
                        }}
                    >
                        {item.icon && <iconify-icon icon={item.icon} class="text-base" />}
                        <span className="text-sm">{item.label}</span>
                    </div>
                );
            })}
        </div>
    );
}
