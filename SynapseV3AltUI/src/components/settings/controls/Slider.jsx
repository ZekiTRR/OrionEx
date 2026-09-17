import React, { useState, useEffect } from 'react';

export function Slider({ min, max, step = 1, value, onChange, unit = '', id }) {
    const [textValue, setTextValue] = useState(String(value ?? min ?? 0));
    const [isFocused, setIsFocused] = useState(false);

    useEffect(() => {
        if (!isFocused) {
            setTextValue(String(value ?? min ?? 0));
        }
    }, [value, isFocused, min]);

    const handleTextChange = (e) => {
        const valStr = e.target.value;
        setTextValue(valStr);
        const parsed = parseInt(valStr, 10);
        if (!isNaN(parsed) && parsed >= min && parsed <= max) {
            onChange?.(parsed);
        }
    };

    const commitValue = () => {
        setIsFocused(false);
        let parsed = parseInt(textValue, 10);
        if (isNaN(parsed)) {
            parsed = Number(value ?? min ?? 0);
        } else {
            parsed = Math.min(Math.max(parsed, min), max);
        }
        setTextValue(String(parsed));
        if (parsed !== value) {
            onChange?.(parsed);
        }
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter') {
            commitValue();
            e.target.blur();
        } else if (e.key === 'Escape') {
            setTextValue(String(value ?? min ?? 0));
            setIsFocused(false);
            e.target.blur();
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            const next = Math.min(Number(value ?? min ?? 0) + step, max);
            setTextValue(String(next));
            onChange?.(next);
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            const next = Math.max(Number(value ?? min ?? 0) - step, min);
            setTextValue(String(next));
            onChange?.(next);
        }
    };

    const inputId = id ? `${id}-input` : undefined;

    return (
        <div className="hw-slider flex items-center gap-2" id={id}>
            <input
                type="range"
                min={min}
                max={max}
                step={step}
                value={value ?? min ?? 0}
                onChange={(e) => {
                    const v = Number(e.target.value);
                    setTextValue(String(v));
                    onChange?.(v);
                }}
                className="cursor-pointer"
            />
            <div className="flex items-center gap-1">
                <input
                    id={inputId}
                    type="number"
                    min={min}
                    max={max}
                    step={step}
                    value={textValue}
                    onFocus={(e) => {
                        setIsFocused(true);
                        e.target.select();
                    }}
                    onBlur={commitValue}
                    onChange={handleTextChange}
                    onKeyDown={handleKeyDown}
                    className="hw-scale-input"
                    title="Click or type to edit value"
                />
                {unit ? <span className="select-none text-xs opacity-75">{unit}</span> : null}
            </div>
        </div>
    );
}
