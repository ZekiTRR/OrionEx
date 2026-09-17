import React, { useEffect, useRef } from 'react';
import { useEditor } from '../../context/EditorContext';
import { useApp } from '../../context/AppContext';
import { themeService } from '../../services/themeService';
import { formatLuaCode } from '../../services/luaFormatter';
import { editorFontFamily, normalizeFontSize } from '../../services/editorFont';

export function MonacoView() {
    const containerRef = useRef(null);
    const { activeTab, updateTabContent, monacoEditorRef, modelsRef } = useEditor();
    const { settings } = useApp();

    useEffect(() => {
        let editor = null;
        let isDisposed = false;

        const initMonaco = () => {
            if (isDisposed || !containerRef.current) return;

            // MonacoPreview loader/workers are loaded locally before React mounts.

            const mon = window.monaco;
            if (!mon) {
                // Wait for Monaco AMD loader
                if (typeof window.require !== 'undefined') {
                    // Loader path is configured by bootstrap.js.
                    window.require(['vs/editor/editor.main'], () => {
                        if (!isDisposed) setupEditor(window.monaco);
                    });
                }
                return;
            }

            setupEditor(mon);
        };

        const setupEditor = (mon) => {
            if (monacoEditorRef.current) {
                editor = monacoEditorRef.current;
            } else {
                // Register lua language if not registered
                const langs = mon.languages.getLanguages();
                if (!langs.some(l => l.id === 'lua')) {
                    mon.languages.register({ id: 'lua' });
                }

                if (!window.__monaco_lua_configured) {
                    window.__monaco_lua_configured = true;

                    mon.languages.setLanguageConfiguration('lua', {
                        comments: {
                            lineComment: '--',
                            blockComment: ['--[[', ']]']
                        },
                        brackets: [
                            ['{', '}'],
                            ['[', ']'],
                            ['(', ')']
                        ],
                        autoClosingPairs: [
                            { open: '{', close: '}' },
                            { open: '[', close: ']' },
                            { open: '(', close: ')' },
                            { open: '"', close: '"', notIn: ['string'] },
                            { open: "'", close: "'", notIn: ['string', 'comment'] }
                        ],
                        surroundingPairs: [
                            { open: '{', close: '}' },
                            { open: '[', close: ']' },
                            { open: '(', close: ')' },
                            { open: '"', close: '"' },
                            { open: "'", close: "'" }
                        ],
                        indentationRules: {
                            increaseIndentPattern: /^((?! \-\-).)*((\b(else|function|then|do|repeat)\b((?! \b(end|until)\b).)*)|(\{\s*))$/,
                            decreaseIndentPattern: /^\s*((\b(elseif|else|end|until)\b)|(\}\s*))\s*$/
                        }
                    });

                    mon.languages.setMonarchTokensProvider('lua', {
                        defaultToken: '',
                        tokenPostfix: '.lua',
                        keywords: [
                            'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
                            'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or',
                            'repeat', 'return', 'then', 'true', 'until', 'while', 'continue',
                            'game', 'print', 'warn', 'error', 'info'
                        ],
                        globals: [
                            'game', 'workspace', 'script', 'Enum', 'Vector3', 'Vector2', 'CFrame',
                            'Color3', 'UDim', 'UDim2', 'Instance', 'TweenInfo', 'BrickColor', 'Ray',
                            'Random', 'NumberSequence', 'ColorSequence', 'NumberRange', 'Rect',
                            'PhysicalProperties', 'task', 'utf8', 'bit32', 'math', 'table', 'string',
                            'os', 'debug', 'coroutine', '_G', '_VERSION', 'shared'
                        ],
                        synapse: [
                            'syn', 'synapse', 'getgenv', 'getrenv', 'getreg', 'getgc', 'filtergc',
                            'getinstances', 'getnilinstances', 'getscripts', 'getloadedmodules',
                            'fireclickdetector', 'fireproximityprompt', 'firetouchinterest',
                            'getrawmetatable', 'setrawmetatable', 'setreadonly', 'isreadonly',
                            'isnetworkowner', 'iswindowactive', 'keypress', 'keyrelease', 'keyclick',
                            'mouse1press', 'mouse1release', 'mouse1click', 'mouse2press', 'mouse2release',
                            'mouse2click', 'mousescroll', 'mousemoverel', 'mousemoveabs', 'iskeydown',
                            'iskeytoggled', 'setclipboard', 'identifyexecutor', 'messagebox',
                            'setwindowtitle', 'setwindowicon', 'hookfunction', 'hookmetamethod',
                            'newcclosure', 'checkcaller', 'clonefunction', 'isourclosure',
                            'getnamecallmethod', 'setnamecallmethod', 'restorefunction'
                        ],
                        builtins: [
                            'assert', 'collectgarbage', 'error', 'getfenv', 'getmetatable', 'ipairs',
                            'load', 'loadfile', 'loadstring', 'module', 'next', 'pairs', 'pcall',
                            'print', 'rawequal', 'rawget', 'rawlen', 'rawset', 'require', 'select',
                            'setfenv', 'setmetatable', 'tonumber', 'tostring', 'type', 'unpack',
                            'xpcall', 'warn', 'tick', 'wait', 'spawn', 'delay', 'info', 'game'
                        ],
                        brackets: [
                            { token: 'delimiter.bracket', open: '{', close: '}' },
                            { token: 'delimiter.array', open: '[', close: ']' },
                            { token: 'delimiter.parenthesis', open: '(', close: ')' }
                        ],
                        operators: [
                            '+', '-', '*', '/', '%', '^', '#', '==', '~=', '<=', '>=', '<', '>', '=',
                            ';', ':', ',', '.', '..', '...'
                        ],
                        symbols: /[=><!~?:&|+\-*\/\^%#]+/,
                        escapes: /\\(?:[abfnrtv\\"']|x[0-9A-Fa-f]{1,2}|[0-9]{1,3})/,

                        tokenizer: {
                            root: [
                                [/(function)(\s+)([a-zA-Z_]\w*)/, ['keyword.function', '', 'entity.name.function']],
                                [/(:)([a-zA-Z_]\w*)/, ['delimiter', 'entity.name.function']],
                                [/([a-zA-Z_]\w*)(\s*)(\()/, [
                                    {
                                        cases: {
                                            '@keywords': 'keyword',
                                            '@globals': 'keyword',
                                            '@synapse': 'keyword',
                                            '@builtins': 'keyword',
                                            '@default': 'entity.name.function'
                                        }
                                    },
                                    '',
                                    '@brackets'
                                ]],
                                [/[a-zA-Z_]\w*/, {
                                    cases: {
                                        '@keywords': 'keyword',
                                        '@globals': 'keyword',
                                        '@synapse': 'keyword',
                                        '@builtins': 'keyword',
                                        '@default': 'identifier'
                                    }
                                }],
                                { include: '@whitespace' },
                                [/[{}()\[\]]/, '@brackets'],
                                [/@symbols/, {
                                    cases: {
                                        '@operators': 'operator',
                                        '@default': ''
                                    }
                                }],
                                [/\d*\.\d+([eE][\-+]?\d+)?/, 'number.float'],
                                [/0[xX][0-9a-fA-F]+/, 'number.hex'],
                                [/\d+/, 'number'],
                                [/[;,.]/, 'delimiter'],
                                [/"([^"\\]|\\.)*$/, 'string.invalid'],
                                [/'([^'\\]|\\.)*$/, 'string.invalid'],
                                [/"/, 'string', '@string_double'],
                                [/'/, 'string', '@string_single'],
                                [/\[=*\[/, 'string', '@string_block']
                            ],
                            whitespace: [
                                [/[ \t\r\n]+/, ''],
                                [/--\[=*\[/, 'comment', '@comment_block'],
                                [/--.*$/, 'comment']
                            ],
                            comment_block: [
                                [/[^\]]+/, 'comment'],
                                [/\]=*\]/, 'comment', '@pop'],
                                [/./, 'comment']
                            ],
                            string_block: [
                                [/[^\]]+/, 'string'],
                                [/\]=*\]/, 'string', '@pop'],
                                [/./, 'string']
                            ],
                            string_double: [
                                [/[^\\"]+/, 'string'],
                                [/@escapes/, 'string.escape'],
                                [/\\./, 'string.escape.invalid'],
                                [/"/, 'string', '@pop']
                            ],
                            string_single: [
                                [/[^\\']+/, 'string'],
                                [/@escapes/, 'string.escape'],
                                [/\\./, 'string.escape.invalid'],
                                [/'/, 'string', '@pop']
                            ]
                        }
                    });

                    mon.languages.registerDocumentFormattingEditProvider('lua', {
                        provideDocumentFormattingEdits(model) {
                            const formatted = formatLuaCode(model.getValue());
                            return [{
                                range: model.getFullModelRange(),
                                text: formatted
                            }];
                        }
                    });
                }

                // UI-only: no language-server process or network connection.

                // Create Monaco Editor
                editor = mon.editor.create(containerRef.current, {
                    language: 'lua',
                    automaticLayout: true,
                    fontSize: normalizeFontSize(settings.fontsize),
                    fontFamily: editorFontFamily(settings.fontfamily),
                    minimap: {
                        enabled: settings.minimap !== 0,
                        side: settings.minimap === 2 ? 'left' : 'right'
                    },
                    tabSize: settings.tab_length,
                    wordWrap: settings.word_wrap ? 'on' : 'off',
                    smoothScrolling: !!settings.smooth_movement,
                    cursorStyle: 'line',
                    cursorWidth: 2,
                    cursorBlinking: 'smooth',
                    cursorSmoothCaretAnimation: settings.smooth_cursor !== false ? 'on' : 'off',
                    contextmenu: false,
                    renderLineHighlight: 'all',
                    wordBasedSuggestions: 'off',
                    suggestOnTriggerCharacters: true,
                    acceptSuggestionOnEnter: 'on',
                    tabCompletion: 'on',
                    quickSuggestions: {
                        other: true,
                        comments: false,
                        strings: true
                    },
                    scrollbar: {
                        vertical: 'auto',
                        horizontal: 'auto',
                        verticalScrollbarSize: 10,
                        horizontalScrollbarSize: 10,
                        verticalSliderSize: 6,
                        horizontalSliderSize: 6,
                        useShadows: false
                    }
                });

                monacoEditorRef.current = editor;
                window.monacoEditor = editor;

                // Apply current theme
                themeService.applyEditorTheme(themeService.currentThemeId, mon);
            }

            // Sync model for active tab
            if (activeTab) {
                let model = modelsRef.current.get(activeTab.id);
                if (!model) {
                    const uri = mon.Uri.parse(`inmemory://synapse/tab_${activeTab.id}.lua`);
                    model = mon.editor.createModel(activeTab.content || '', 'lua', uri);
                    modelsRef.current.set(activeTab.id, model);

                    model.onDidChangeContent(() => {
                        const val = model.getValue();
                        updateTabContent(activeTab.id, val);
                        
                    });
                }
                editor.setModel(model);
                editor.updateOptions({ readOnly: !!activeTab.readonly });
            }
        };

        initMonaco();

        const refreshMetrics = () => {
            if (isDisposed) return;
            window.monaco?.editor.remeasureFonts();
            editor?.layout();
            editor?.render(true);
        };
        document.fonts?.ready.then(refreshMetrics);
        document.fonts?.addEventListener('loadingdone', refreshMetrics);

        return () => {
            isDisposed = true;
            document.fonts?.removeEventListener('loadingdone', refreshMetrics);
        };
    }, []);

    // When activeTab changes, switch the active model
    useEffect(() => {
        const mon = window.monaco;
        const editor = monacoEditorRef.current;
        if (!mon || !editor || !activeTab) return;

        let model = modelsRef.current.get(activeTab.id);
        if (!model) {
            const uri = mon.Uri.parse(`inmemory://synapse/tab_${activeTab.id}.lua`);
            model = mon.editor.createModel(activeTab.content || '', 'lua', uri);
            modelsRef.current.set(activeTab.id, model);

            model.onDidChangeContent(() => {
                const val = model.getValue();
                updateTabContent(activeTab.id, val);
                
            });
        } else if (model.getValue() !== activeTab.content && !editor.hasTextFocus()) {
            model.setValue(activeTab.content || '');
        }

        editor.setModel(model);
        editor.updateOptions({ readOnly: !!activeTab.readonly });
    }, [activeTab?.id]);

    // Update editor options when settings change
    useEffect(() => {
        const editor = monacoEditorRef.current;
        if (!editor) return;

        editor.updateOptions({
            fontSize: normalizeFontSize(settings.fontsize),
            fontFamily: editorFontFamily(settings.fontfamily),
            tabSize: settings.tab_length,
            wordWrap: settings.word_wrap ? 'on' : 'off',
            smoothScrolling: !!settings.smooth_movement,
            cursorStyle: 'line',
            cursorWidth: 2,
            cursorBlinking: 'smooth',
            cursorSmoothCaretAnimation: settings.smooth_cursor !== false ? 'on' : 'off',
            minimap: {
                enabled: settings.minimap !== 0,
                side: settings.minimap === 2 ? 'left' : 'right'
            }
        });
        window.monaco?.editor.remeasureFonts();
        editor.layout();
        editor.render(true);
    }, [settings]);

    // Update Monaco editor theme when theme changes
    useEffect(() => {
        const handleThemeChange = (theme) => {
            const mon = window.monaco;
            if (mon && monacoEditorRef.current) {
                themeService.applyEditorTheme(theme.id, mon);
            }
        };

        const unsubscribe = themeService.subscribe(handleThemeChange);

        const onThemeChangedDoc = (e) => {
            if (e.detail?.id) {
                const mon = window.monaco;
                if (mon && monacoEditorRef.current) {
                    themeService.applyEditorTheme(e.detail.id, mon);
                }
            }
        };
        document.addEventListener('theme:changed', onThemeChangedDoc);

        return () => {
            unsubscribe();
            document.removeEventListener('theme:changed', onThemeChangedDoc);
        };
    }, []);

    return (
        <div className="main-container relative flex-1 h-full w-full overflow-hidden">
            <div id="monaco-editor" ref={containerRef} className="absolute inset-0" />
        </div>
    );
}
