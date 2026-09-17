import test from 'node:test';
import assert from 'node:assert/strict';

const { normalizeFontSize, editorFontFamily } = await import('../src/services/editorFont.js');

test('font size clamps and falls back to 16', () => {
    assert.equal(normalizeFontSize(16), 16);
    assert.equal(normalizeFontSize('20'), 20);
    assert.equal(normalizeFontSize(2), 8);
    assert.equal(normalizeFontSize(99), 48);
    assert.equal(normalizeFontSize(12.4), 12);
    assert.equal(normalizeFontSize('abc'), 16);
    assert.equal(normalizeFontSize(null), 16);
    assert.equal(normalizeFontSize(''), 16);
    assert.equal(normalizeFontSize('   '), 16);
    assert.equal(normalizeFontSize(Infinity), 16);
});

test('font family string quotes the family and keeps fallbacks', () => {
    assert.equal(editorFontFamily('Cascadia Code'), '"Cascadia Code", Editor, Consolas, monospace');
    assert.equal(editorFontFamily('Segoe UI'), '"Segoe UI", Editor, Consolas, monospace');
    assert.equal(editorFontFamily(''), 'Editor, Consolas, monospace');
    assert.equal(editorFontFamily('   '), 'Editor, Consolas, monospace');
    assert.equal(editorFontFamily(null), 'Editor, Consolas, monospace');
    assert.equal(editorFontFamily(42), 'Editor, Consolas, monospace');
});
