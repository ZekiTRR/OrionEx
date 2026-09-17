export function normalizeFontSize(value) {
    const size = Number(value);
    return value == null || String(value).trim() === '' || !Number.isFinite(size)
        ? 16 : Math.max(8, Math.min(48, Math.round(size)));
}

export function editorFontFamily(value) {
    const family = typeof value === 'string' ? value.trim() : '';
    return family ? `${JSON.stringify(family)}, Editor, Consolas, monospace` : 'Editor, Consolas, monospace';
}
