/**
 * luaFormatter.js
 * Lua formatting and AST-aware indentation provider for Monaco Editor.
 */

export function formatLuaCode(code) {
    if (!code) return '';

    const placeholders = [];
    const hideLiteral = (match) => {
        const id = `___LUA_LIT_${placeholders.length}___`;
        placeholders.push({ id, text: match });
        return id;
    };

    // 1. Protect comments and string literals
    let text = code.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, hideLiteral);
    text = text.replace(/\[(=*)\[[\s\S]*?\]\1\]/g, hideLiteral);
    text = text.replace(/--[^\r\n]*/g, hideLiteral);
    text = text.replace(/"(?:[^"\\]|\\.)*"/g, hideLiteral);
    text = text.replace(/'(?:[^'\\]|\\.)*'/g, hideLiteral);

    // 2. Format line by line
    const rawLines = text.split(/\r?\n/);
    let indentLevel = 0;
    const indentStr = '    '; // 4 spaces

    const formattedLines = rawLines.map((rawLine) => {
        let line = rawLine.trim();
        if (!line) return '';

        // Space commas & semicolons
        line = line.replace(/,\s*/g, ', ');
        line = line.replace(/;\s*/g, '; ');

        // Space compound assignments (+=, -=, *=, /=, %=, ^=, ..=)
        line = line.replace(/([a-zA-Z0-9_\]\)])\s*([\+\-*\/%^]|\.\.)=\s*([a-zA-Z0-9_\[\("'(-])/g, '$1 $2= $3');

        // Space comparison operators (==, ~=, <=, >=)
        line = line.replace(/([a-zA-Z0-9_\]\)"'])\s*(==|~=|<=|>=)\s*([a-zA-Z0-9_\[\('"(-])/g, '$1 $2 $3');

        // Space single assignment =
        line = line.replace(/([^=<>~+\-*\/%^!.\s])\s*=\s*([^=])/g, '$1 = $2');
        line = line.replace(/([a-zA-Z0-9_\]\)"'])\s*=\s*/g, '$1 = ');
        line = line.replace(/\s*=\s*([a-zA-Z0-9_\[\("'{])/g, ' = $1');

        // Space string concatenation ..
        line = line.replace(/([^\s.])\s*\.\.\s*([^\s.])/g, '$1 .. $2');

        // Space binary arithmetic operators (+, -, *, /, %, ^)
        line = line.replace(/([a-zA-Z0-9_\]\)'"])\s*([\+\*\/%^])\s*([a-zA-Z0-9_\[\('"(-])/g, '$1 $2 $3');
        line = line.replace(/([a-zA-Z0-9_\]\)'"])\s*-\s*([a-zA-Z0-9_\[\('"(-])/g, '$1 - $2');

        // Space comparisons (<, >)
        line = line.replace(/([a-zA-Z0-9_\]\)'"])\s*([<>])\s*([a-zA-Z0-9_\[\('"(-])/g, '$1 $2 $3');

        // Space logical keywords
        line = line.replace(/\b(and|or)\b/g, ' $1 ');

        // Normalize internal whitespace
        line = line.replace(/[ \t]{2,}/g, ' ');

        // Block indentation tracking:
        let opensCount = 0;
        const funcMatches = line.match(/\bfunction\b/g) || [];
        const repeatMatches = line.match(/\brepeat\b/g) || [];
        const doMatches = line.match(/\bdo\b/g) || [];
        const braceOpenMatches = line.match(/\{/g) || [];
        opensCount += funcMatches.length + repeatMatches.length + doMatches.length + braceOpenMatches.length;

        // Match 'if ... then' while ignoring 'elseif ... then'
        const strippedLine = line.replace(/\belseif\b.*?\bthen\b/g, '');
        const ifThenMatches = strippedLine.match(/\bif\b.*?\bthen\b/g) || [];
        opensCount += ifThenMatches.length;

        // Count closers: 'end', 'until', '}'
        const endMatches = line.match(/\bend\b/g) || [];
        const untilMatches = line.match(/\buntil\b/g) || [];
        const braceCloseMatches = line.match(/\}/g) || [];
        const closesCount = endMatches.length + untilMatches.length + braceCloseMatches.length;

        // Count leading closers at start of line
        let leadingClosers = 0;
        let tempLine = line;
        while (/^(\bend\b|\buntil\b|\})/.test(tempLine)) {
            leadingClosers++;
            tempLine = tempLine.replace(/^(\bend\b|\buntil\b|\})[,\)\s]*/, '').trim();
        }

        const startsWithBranch = /^(\belse\b|\belseif\b)/.test(line);

        let currentLineIndent = indentLevel;
        if (leadingClosers > 0) {
            currentLineIndent = Math.max(0, indentLevel - leadingClosers);
        } else if (startsWithBranch) {
            currentLineIndent = Math.max(0, indentLevel - 1);
        }

        // Update indent level for following lines
        indentLevel = Math.max(0, indentLevel + opensCount - closesCount);

        return indentStr.repeat(currentLineIndent) + line;
    });

    let result = formattedLines.join('\n');

    // 3. Restore protected literals & comments
    for (let i = placeholders.length - 1; i >= 0; i--) {
        const p = placeholders[i];
        result = result.split(p.id).join(p.text);
    }

    return result;
}
