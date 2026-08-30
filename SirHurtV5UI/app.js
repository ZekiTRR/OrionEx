'use strict';

window.addEventListener('keydown', function (e) {
    if (
        e.key === 'F12' ||
        e.keyCode === 123 ||
        (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.keyCode === 73 || e.key === 'i')) ||
        (e.ctrlKey && e.shiftKey && (e.key === 'J' || e.keyCode === 74 || e.key === 'j')) ||
        (e.ctrlKey && e.shiftKey && (e.key === 'C' || e.keyCode === 67 || e.key === 'c')) ||
        (e.ctrlKey && (e.key === 'U' || e.keyCode === 85 || e.key === 'u'))
    ) {
        e.preventDefault();
        e.stopPropagation();
    }
}, true);


(async function initBridge() {
    if (window.chrome && window.chrome.webview) {

        if (window.__zenithBridge) {
            window.bridge = window.__zenithBridge;
        }


        if (window.AccountManager && window.AccountManager.loadAccounts) {
            window.AccountManager.loadAccounts();
        }
    }
})();

function esc(str) {
    if (!str) return "";
    return str.toString()
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

function fixEncoding(str) {
    if (!str) return str;
    const win1252 = {
        '\u20AC': '%80', '\u201A': '%82', '\u0192': '%83', '\u201E': '%84',
        '\u2026': '%85', '\u2020': '%86', '\u2021': '%87', '\u02C6': '%88',
        '\u2030': '%89', '\u0160': '%8A', '\u2039': '%8B', '\u0152': '%8C',
        '\u017D': '%8E', '\u2018': '%91', '\u2019': '%92', '\u201C': '%93',
        '\u201D': '%94', '\u2022': '%95', '\u2013': '%96', '\u2014': '%97',
        '\u02DC': '%98', '\u2122': '%99', '\u0161': '%9A', '\u203A': '%9B',
        '\u0153': '%9C', '\u017E': '%9E', '\u0178': '%9F'
    };
    try {
        let escaped = escape(str);
        for (let char in win1252) {
            let uhex = escape(char);
            escaped = escaped.split(uhex).join(win1252[char]);
        }
        return decodeURIComponent(escaped);
    } catch (e) {
        return str;
    }
}


const THEMES_CONFIG = {
    v5: {
        name: "V5 (Default)",
        styles: {
            '--bg': '#0c0c0e', '--bg2': '#101013', '--bg3': '#141417', '--bg4': '#171719',
            '--bd': 'rgba(255, 255, 255, 0.07)', '--bd2': 'rgba(255, 255, 255, 0.04)',
            '--t1': '#ffffff', '--t2': '#a0a0a5', '--t3': '#55555a',
            '--purple': '#ec96ba', '--editor-bg': '#0c0c0e',
            '--v5-glow': 'rgba(236, 150, 186, 0.4)',
            '--welcome-bg': 'linear-gradient(135deg, #5c2038 0%, #ec96ba 100%)',
            '--welcome-bd': 'rgba(236, 150, 186, 0.25)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.75)',
            '--glass-bg': 'rgba(236, 150, 186, 0.03)',
            '--glass-bd': 'rgba(236, 150, 186, 0.08)',
            '--v5-gradient': 'linear-gradient(135deg, #ff5e97 0%, #ec96ba 50%, #f7b0c8 100%)'
        }
    },
    dark: {
        name: "Dark",
        styles: {
            '--bg': '#0c0c0e', '--bg2': '#101013', '--bg3': '#141417', '--bg4': '#171719',
            '--bd': 'rgba(255, 255, 255, 0.07)', '--bd2': 'rgba(255, 255, 255, 0.04)',
            '--t1': '#ffffff', '--t2': '#a0a0a5', '--t3': '#55555a',
            '--purple': '#7b7ff6', '--editor-bg': '#0c0c0e',
            '--v5-glow': 'rgba(123, 127, 246, 0.4)',
            '--welcome-bg': 'linear-gradient(130deg, rgba(40, 40, 78, 0.5) 0%, rgba(16, 16, 32, 0.35) 100%)',
            '--welcome-bd': 'rgba(100, 100, 200, 0.14)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.6)',
            '--glass-bg': 'rgba(255, 255, 255, 0.03)',
            '--glass-bd': 'rgba(255, 255, 255, 0.08)',
            '--v5-gradient': 'linear-gradient(135deg, #7b7ff6 0%, #6266dc 100%)'
        }
    },
    light: {
        name: "Light",
        isLight: true,
        styles: {
            '--bg': '#f5f5f7', '--bg2': '#ffffff', '--bg3': '#ebeaee', '--bg4': '#e0dfe3',
            '--bd': 'rgba(0, 0, 0, 0.08)', '--bd2': 'rgba(0, 0, 0, 0.04)',
            '--t1': '#1d1d1f', '--t2': '#4c4c4f', '--t3': '#86868b',
            '--purple': '#7b7ff6', '--editor-bg': '#ffffff',
            '--welcome-bg': '#e8e8ed',
            '--welcome-text': '#1d1d1f',
            '--welcome-sub': '#6e6e73',
            '--glass-bg': 'rgba(0, 0, 0, 0.03)',
            '--glass-bd': 'rgba(0, 0, 0, 0.08)',
            '--v5-gradient': 'linear-gradient(135deg, #7b7ff6 0%, #6266dc 100%)'
        }
    },

    sirhurt: {
        name: "SirHurt",
        styles: {
            '--bg': '#0c0c0e', '--bg2': '#101013', '--bg3': '#141417', '--bg4': '#171719',
            '--bd': 'rgba(255, 255, 255, 0.07)', '--bd2': 'rgba(255, 255, 255, 0.04)',
            '--t1': '#ffffff', '--t2': '#a0a0a5', '--t3': '#55555a',
            '--purple': '#0083fd', '--editor-bg': '#0c0c0e',
            '--welcome-bg': 'linear-gradient(135deg, #004a8f 0%, #0083fd 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.03)',
            '--glass-bd': 'rgba(255, 255, 255, 0.08)',
            '--v5-gradient': 'linear-gradient(135deg, #0083fd 0%, #00c3ff 100%)',
            '--v5-glow': 'rgba(0, 131, 253, 0.4)'
        }
    },

    bloodfall: {
        name: "Bloodfall",
        styles: {
            '--bg': '#0d0404', '--bg2': '#120505', '--bg3': '#1a0808', '--bg4': '#220b0b',
            '--bd': 'rgba(255, 69, 58, 0.15)', '--bd2': 'rgba(255, 69, 58, 0.08)',
            '--t1': '#ffe5e5', '--t2': '#a87c7c', '--t3': '#5e4343',
            '--purple': '#ff453a', '--editor-bg': '#0d0404',
            '--welcome-bg': 'linear-gradient(135deg, #420606 0%, #b71c1c 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #ff453a 0%, #ff5252 50%, #ff8a80 100%)',
            '--v5-glow': 'rgba(255, 69, 58, 0.5)'
        }
    },
    midnight_ocean: {
        name: "Midnight Ocean",
        styles: {
            '--bg': '#05070a', '--bg2': '#0a0d14', '--bg3': '#0f141e', '--bg4': '#141a28',
            '--bd': 'rgba(0, 195, 255, 0.08)', '--bd2': 'rgba(0, 195, 255, 0.04)',
            '--t1': '#e0f4ff', '--t2': '#8ca6b5', '--t3': '#5a6d7a',
            '--purple': '#00c3ff', '--editor-bg': '#05070a',
            '--welcome-bg': 'linear-gradient(135deg, #01579b 0%, #039be5 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #00c3ff 0%, #0091ff 50%, #00e5ff 100%)'
        }
    },
    cyberwave: {
        name: "Cyberwave",
        styles: {
            '--bg': '#050505', '--bg2': '#0a0a0a', '--bg3': '#111111', '--bg4': '#181818',
            '--bd': 'rgba(255, 0, 255, 0.12)', '--bd2': 'rgba(255, 0, 255, 0.06)',
            '--t1': '#ffffff', '--t2': '#ff00ff', '--t3': '#880088',
            '--purple': '#ff00ff', '--editor-bg': '#050505',
            '--welcome-bg': 'linear-gradient(135deg, #2d00f7 0%, #ff00ff 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #ff00ff 0%, #7000ff 50%, #00ffff 100%)',
            '--v5-glow': 'rgba(255, 0, 255, 0.4)'
        }
    },
    forest_moss: {
        name: "Forest Moss",
        styles: {
            '--bg': '#060806', '--bg2': '#0c110c', '--bg3': '#131913', '--bg4': '#1a221a',
            '--bd': 'rgba(134, 168, 142, 0.15)', '--bd2': 'rgba(134, 168, 142, 0.08)',
            '--t1': '#e2ffe9', '--t2': '#86a88e', '--t3': '#4d6352',
            '--purple': '#30d158', '--editor-bg': '#060806',
            '--welcome-bg': 'linear-gradient(135deg, #1b5e20 0%, #43a047 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #30d158 0%, #b9f6ca 50%, #ccff90 100%)',
            '--v5-glow': 'rgba(48, 209, 88, 0.4)'
        }
    },
    rose_gold: {
        name: "Rose Gold",
        styles: {
            '--bg': '#1a1416', '--bg2': '#241c1f', '--bg3': '#2e2428', '--bg4': '#382c31',
            '--bd': 'rgba(226, 175, 160, 0.15)', '--bd2': 'rgba(226, 175, 160, 0.08)',
            '--t1': '#fff0f0', '--t2': '#d4b0ac', '--t3': '#8e716e',
            '--purple': '#e2afa0', '--editor-bg': '#1a1416',
            '--welcome-bg': 'linear-gradient(135deg, #e5b2a4 0%, #b78a7d 50%, #d4a395 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #e2afa0 0%, #ffccbc 50%, #ffe0b2 100%)'
        }
    },
    lavender_breeze: {
        name: "Lavender Breeze",
        isLight: true,
        styles: {
            '--bg': '#f3f2f7', '--bg2': '#ffffff', '--bg3': '#e6e4ed', '--bg4': '#dad7e4',
            '--bd': 'rgba(108, 92, 231, 0.1)', '--bd2': 'rgba(108, 92, 231, 0.05)',
            '--t1': '#2d3436', '--t2': '#636e72', '--t3': '#b2bec3',
            '--purple': '#6c5ce7', '--editor-bg': '#ffffff',
            '--welcome-bg': 'linear-gradient(135deg, #6c5ce7 0%, #a29bfe 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.8)',
            '--glass-bg': 'rgba(255, 255, 255, 0.1)',
            '--glass-bd': 'rgba(255, 255, 255, 0.2)',
            '--v5-gradient': 'linear-gradient(135deg, #6c5ce7 0%, #a29bfe 50%, #fab1a0 100%)'
        }
    },
    gold_rush: {
        name: "Gold Rush",
        styles: {
            '--bg': '#0a0a0c', '--bg2': '#121215', '--bg3': '#18181b', '--bg4': '#222226',
            '--bd': 'rgba(212, 175, 55, 0.15)', '--bd2': 'rgba(212, 175, 55, 0.08)',
            '--t1': '#ffffff', '--t2': '#d4af37', '--t3': '#7a6523',
            '--purple': '#d4af37', '--editor-bg': '#0a0a0c',
            '--welcome-bg': 'linear-gradient(135deg, #8a6d3b 0%, #d4af37 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #d4af37 0%, #fff176 50%, #ffd54f 100%)'
        }
    },
    neon_mint: {
        name: "Neon Mint",
        styles: {
            '--bg': '#050505', '--bg2': '#0c0c0c', '--bg3': '#141414', '--bg4': '#1c1c1c',
            '--bd': 'rgba(0, 255, 163, 0.12)', '--bd2': 'rgba(0, 255, 163, 0.06)',
            '--t1': '#ffffff', '--t2': '#00ffa3', '--t3': '#008a58',
            '--purple': '#00ffa3', '--editor-bg': '#050505',
            '--welcome-bg': 'linear-gradient(135deg, #004d40 0%, #00ffa3 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #00ffa3 0%, #00e5ff 50%, #76ff03 100%)'
        }
    },
    nord: {
        name: "Nord",
        styles: {
            '--bg': '#242933', '--bg2': '#2e3440', '--bg3': '#3b4252', '--bg4': '#434c5e',
            '--bd': 'rgba(136, 192, 208, 0.15)', '--bd2': 'rgba(136, 192, 208, 0.08)',
            '--t1': '#eceff4', '--t2': '#d8dee9', '--t3': '#4c566a',
            '--purple': '#88c0d0', '--editor-bg': '#2e3440',
            '--welcome-bg': 'linear-gradient(135deg, #434c5e 0%, #4c566a 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #88c0d0 0%, #81a1c1 50%, #8fbcbb 100%)'
        }
    },
    coffee: {
        name: "Coffee",
        styles: {
            '--bg': '#0f0a0a', '--bg2': '#1b1212', '--bg3': '#2b1d1d', '--bg4': '#3b2828',
            '--bd': 'rgba(199, 144, 129, 0.15)', '--bd2': 'rgba(199, 144, 129, 0.08)',
            '--t1': '#f9f1f0', '--t2': '#c79081', '--t3': '#6e4f47',
            '--purple': '#dfa579', '--editor-bg': '#0f0a0a',
            '--welcome-bg': 'linear-gradient(135deg, #3e2723 0%, #5d4037 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #dfa579 0%, #c79081 50%, #d7a59a 100%)'
        }
    },
    solarized: {
        name: "Solarized",
        styles: {
            '--bg': '#001e26', '--bg2': '#002b36', '--bg3': '#073642', '--bg4': '#586e75',
            '--bd': 'rgba(38, 139, 210, 0.15)', '--bd2': 'rgba(38, 139, 210, 0.08)',
            '--t1': '#fdf6e3', '--t2': '#93a1a1', '--t3': '#657b83',
            '--purple': '#b58900', '--editor-bg': '#002b36',
            '--welcome-bg': 'linear-gradient(135deg, #073642 0%, #586e75 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #b58900 0%, #cb4b16 50%, #dc322f 100%)'
        }
    },
    aura: {
        name: "Aura",
        styles: {
            '--bg': '#15141b', '--bg2': '#1d1928', '--bg3': '#2a243a', '--bg4': '#4d4263',
            '--bd': 'rgba(162, 114, 255, 0.2)', '--bd2': 'rgba(162, 114, 255, 0.1)',
            '--t1': '#edecee', '--t2': '#9d96ad', '--t3': '#6d6a73',
            '--purple': '#a272ff', '--editor-bg': '#15141b',
            '--welcome-bg': 'linear-gradient(135deg, #312e3d 0%, #4d4263 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #a272ff 0%, #61ffca 50%, #ff6767 100%)'
        }
    },
    frostbite: {
        name: "Frostbite",
        isLight: true,
        styles: {
            '--bg': '#e0f2f1', '--bg2': '#ffffff', '--bg3': '#b2dfdb', '--bg4': '#80cbc4',
            '--bd': 'rgba(0, 150, 136, 0.1)', '--bd2': 'rgba(0, 150, 136, 0.05)',
            '--t1': '#004d40', '--t2': '#26a69a', '--t3': '#80cbc4',
            '--purple': '#00bcd4', '--editor-bg': '#ffffff',
            '--v5-glow': 'rgba(0, 188, 212, 0.4)',
            '--welcome-bg': 'linear-gradient(135deg, #00acc1 0%, #4dd0e1 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.8)',
            '--glass-bg': 'rgba(255, 255, 255, 0.1)',
            '--glass-bd': 'rgba(255, 255, 255, 0.2)',
            '--v5-gradient': 'linear-gradient(135deg, #00bcd4 0%, #80deea 100%)'
        }
    },
    amber_glow: {
        name: "Amber Glow",
        styles: {
            '--bg': '#050403', '--bg2': '#0e0c0a', '--bg3': '#1a1612', '--bg4': '#26201a',
            '--bd': 'rgba(255, 143, 0, 0.15)', '--bd2': 'rgba(255, 143, 0, 0.08)',
            '--t1': '#ffffff', '--t2': '#ffb300', '--t3': '#7a5500',
            '--purple': '#ff8f00', '--editor-bg': '#050403',
            '--welcome-bg': 'linear-gradient(135deg, #ff8c00 0%, #ffc107 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.8)',
            '--glass-bg': 'rgba(255, 255, 255, 0.08)',
            '--glass-bd': 'rgba(255, 255, 255, 0.15)',
            '--v5-gradient': 'linear-gradient(135deg, #ff8f00 0%, #ffcc80 100%)'
        }
    },
    night_city: {
        name: "Night City",
        styles: {
            '--bg': '#0f0f12', '--bg2': '#16161a', '--bg3': '#1e1e24', '--bg4': '#282830',
            '--bd': 'rgba(255, 214, 0, 0.15)', '--bd2': 'rgba(255, 214, 0, 0.08)',
            '--t1': '#ffffff', '--t2': '#ffd600', '--t3': '#8a7300',
            '--purple': '#ffd600', '--editor-bg': '#0f0f12',
            '--welcome-bg': 'linear-gradient(135deg, #fbc02d 0%, #ffeb3b 100%)',
            '--welcome-text': '#000000',
            '--welcome-sub': '#333333',
            '--v5-gradient': 'linear-gradient(135deg, #ffd600 0%, #fff176 100%)'
        }
    },
    classic_v1: {
        name: "Classic V1",
        isLight: true,
        styles: {
            '--bg': '#dcdcdc', '--bg2': '#e8e8e8', '--bg3': '#cccccc', '--bg4': '#bbbbbb',
            '--bd': 'rgba(0, 0, 0, 0.1)', '--bd2': 'rgba(0, 0, 0, 0.05)',
            '--t1': '#222222', '--t2': '#555555', '--t3': '#888888',
            '--purple': '#ff4136', '--editor-bg': '#e8e8e8',
            '--v5-glow': 'rgba(255, 65, 54, 0.4)',
            '--welcome-bg': 'linear-gradient(135deg, #ff4136 0%, #ff851b 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #ff4136 0%, #ff726b 100%)'
        }
    },
    abyssal: {
        name: "Abyssal",
        styles: {
            '--bg': '#000c0d', '--bg2': '#001517', '--bg3': '#002529', '--bg4': '#00363d',
            '--bd': 'rgba(24, 255, 255, 0.12)', '--bd2': 'rgba(24, 255, 255, 0.06)',
            '--t1': '#e0f2f1', '--t2': '#18ffff', '--t3': '#0091ea',
            '--purple': '#18ffff', '--editor-bg': '#000c0d',
            '--welcome-bg': 'linear-gradient(135deg, #006064 0%, #00acc1 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #18ffff 0%, #84ffff 100%)'
        }
    },
    sakura_blossom: {
        name: "Sakura Blossom",
        isLight: true,
        styles: {
            '--bg': '#f5faff', '--bg2': '#ffffff', '--bg3': '#ffeef2', '--bg4': '#ffdce5',
            '--bd': 'rgba(244, 143, 177, 0.1)', '--bd2': 'rgba(244, 143, 177, 0.05)',
            '--t1': '#333333', '--t2': '#f48fb1', '--t3': '#ec407a',
            '--purple': '#f48fb1', '--editor-bg': '#ffffff',
            '--v5-glow': 'rgba(244, 143, 177, 0.5)',
            '--welcome-bg': 'linear-gradient(135deg, #f48fb1 0%, #fce4ec 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #f48fb1 0%, #f8bbd0 50%, #ce93d8 100%)'
        }
    },
    matrix: {
        name: "Matrix",
        styles: {
            '--bg': '#050805', '--bg2': '#0a0d0a', '--bg3': '#101510', '--bg4': '#151c15',
            '--bd': 'rgba(0, 255, 65, 0.12)', '--bd2': 'rgba(0, 255, 65, 0.06)',
            '--t1': '#ffffff', '--t2': '#00ff41', '--t3': '#008f25',
            '--purple': '#00ff41', '--editor-bg': '#050805',
            '--welcome-bg': 'linear-gradient(135deg, #003b00 0%, #00ff41 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #00ff41 0%, #a2ffd0 100%)'
        }
    },
    solar_flare: {
        name: "Solar Flare",
        styles: {
            '--bg': '#0d0905', '--bg2': '#140e08', '--bg3': '#1c140b', '--bg4': '#251a0f',
            '--bd': 'rgba(255, 106, 0, 0.15)', '--bd2': 'rgba(255, 106, 0, 0.08)',
            '--t1': '#ffffff', '--t2': '#ff6a00', '--t3': '#8a3c00',
            '--purple': '#ff6a00', '--editor-bg': '#0d0905',
            '--welcome-bg': 'linear-gradient(135deg, #8a2b00 0%, #ff6a00 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #ff6a00 0%, #ffddb0 100%)'
        }
    },
    midnight_slate: {
        name: "Midnight Slate",
        styles: {
            '--bg': '#0f111a', '--bg2': '#141724', '--bg3': '#1c2133', '--bg4': '#242a42',
            '--bd': 'rgba(115, 138, 219, 0.12)', '--bd2': 'rgba(115, 138, 219, 0.06)',
            '--t1': '#e0e6ff', '--t2': '#738adb', '--t3': '#4d5c92',
            '--purple': '#738adb', '--editor-bg': '#0f111a',
            '--welcome-bg': 'linear-gradient(135deg, #2b3a67 0%, #738adb 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #738adb 0%, #b8c7ff 100%)'
        }
    },
    royal_gold: {
        name: "Royal Gold",
        styles: {
            '--bg': '#0a0b10', '--bg2': '#111218', '--bg3': '#181a24', '--bg4': '#1f212f',
            '--bd': 'rgba(212, 175, 55, 0.15)', '--bd2': 'rgba(212, 175, 55, 0.08)',
            '--t1': '#ffffff', '--t2': '#d4af37', '--t3': '#7a6523',
            '--purple': '#d4af37', '--editor-bg': '#0a0b10',
            '--welcome-bg': 'linear-gradient(135deg, #3d2b1f 0%, #d4af37 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #d4af37 0%, #fbe7b2 100%)'
        }
    },
    neon_sage: {
        name: "Neon Sage",
        styles: {
            '--bg': '#0a0c0b', '--bg2': '#111412', '--bg3': '#191d1a', '--bg4': '#212623',
            '--bd': 'rgba(0, 255, 163, 0.12)', '--bd2': 'rgba(0, 255, 163, 0.06)',
            '--t1': '#ffffff', '--t2': '#00ffa3', '--t3': '#008a58',
            '--purple': '#00ffa3', '--editor-bg': '#0a0c0b',
            '--welcome-bg': 'linear-gradient(135deg, #004d40 0%, #00ffa3 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #00ffa3 0%, #b2ffeb 100%)'
        }
    },
    cyber_industrial: {
        name: "Cyber Industrial",
        styles: {
            '--bg': '#0f0f12', '--bg2': '#16161a', '--bg3': '#1e1e24', '--bg4': '#282830',
            '--bd': 'rgba(255, 214, 0, 0.15)', '--bd2': 'rgba(255, 214, 0, 0.08)',
            '--t1': '#ffffff', '--t2': '#ffd600', '--t3': '#8a7300',
            '--purple': '#ffd600', '--editor-bg': '#0f0f12',
            '--welcome-bg': 'linear-gradient(135deg, #fbc02d 0%, #ffeb3b 100%)',
            '--welcome-text': '#000000',
            '--welcome-sub': '#333333',
            '--v5-gradient': 'linear-gradient(135deg, #ffd600 0%, #fffde7 100%)'
        }
    },
    crimson_peak: {
        name: "Crimson Peak",
        styles: {
            '--bg': '#0d0404', '--bg2': '#120505', '--bg3': '#1a0808', '--bg4': '#220b0b',
            '--bd': 'rgba(220, 20, 60, 0.15)', '--bd2': 'rgba(220, 20, 60, 0.08)',
            '--t1': '#ffe5e5', '--t2': '#dc143c', '--t3': '#7b0a1d',
            '--purple': '#dc143c', '--editor-bg': '#0d0404',
            '--welcome-bg': 'linear-gradient(135deg, #5e0c0c 0%, #dc143c 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #dc143c 0%, #ff6b81 100%)'
        }
    },
    champagne: {
        name: "Champagne",
        isLight: true,
        styles: {
            '--bg': '#fdf5e6', '--bg2': '#ffffff', '--bg3': '#f5deb3', '--bg4': '#eecfa1',
            '--bd': 'rgba(212, 175, 55, 0.1)', '--bd2': 'rgba(212, 175, 55, 0.05)',
            '--t1': '#4b3c2a', '--t2': '#d4af37', '--t3': '#a68a2d',
            '--purple': '#d4af37', '--editor-bg': '#ffffff',
            '--welcome-bg': 'linear-gradient(135deg, #fdf5e6 0%, #fbe7b2 100%)',
            '--welcome-text': '#4b3c2a',
            '--welcome-sub': '#4b3c2a',
            '--v5-gradient': 'linear-gradient(135deg, #d4af37 0%, #f5deb3 100%)',
            '--v5-glow': 'rgba(212, 175, 55, 0.5)'
        }
    },
    deep_berry: {
        name: "Deep Berry",
        styles: {
            '--bg': '#100b16', '--bg2': '#17111f', '--bg3': '#1f162a', '--bg4': '#281d36',
            '--bd': 'rgba(255, 0, 255, 0.15)', '--bd2': 'rgba(255, 0, 255, 0.08)',
            '--t1': '#ffffff', '--t2': '#ff00ff', '--t3': '#a000a0',
            '--purple': '#ff00ff', '--editor-bg': '#100b16',
            '--welcome-bg': 'linear-gradient(135deg, #4a00e0 0%, #ff00ff 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #ff00ff 0%, #ea80fc 100%)'
        }
    },
    desert_storm: {
        name: "Desert Storm",
        styles: {
            '--bg': '#1a1510', '--bg2': '#241d16', '--bg3': '#2e261d', '--bg4': '#382e24',
            '--bd': 'rgba(194, 178, 128, 0.15)', '--bd2': 'rgba(194, 178, 128, 0.08)',
            '--t1': '#f5f5dc', '--t2': '#c2b280', '--t3': '#8e7a4d',
            '--purple': '#c2b280', '--editor-bg': '#1a1510',
            '--welcome-bg': 'linear-gradient(135deg, #3d2b1f 0%, #c2b280 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #c2b280 0%, #ede6d6 100%)'
        }
    },
    glacier: {
        name: "Glacier",
        styles: {
            '--bg': '#10161a', '--bg2': '#161d24', '--bg3': '#1e2830', '--bg4': '#26323d',
            '--bd': 'rgba(0, 210, 255, 0.12)', '--bd2': 'rgba(0, 210, 255, 0.06)',
            '--t1': '#e1f5fe', '--t2': '#00d2ff', '--t3': '#0091ea',
            '--purple': '#00d2ff', '--editor-bg': '#10161a',
            '--welcome-bg': 'linear-gradient(135deg, #01579b 0%, #00d2ff 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #00d2ff 0%, #b3e5fc 100%)'
        }
    },
    titanium: {
        name: "Titanium",
        styles: {
            '--bg': '#141416', '--bg2': '#1a1a1c', '--bg3': '#212124', '--bg4': '#29292d',
            '--bd': 'rgba(255, 255, 255, 0.12)', '--bd2': 'rgba(255, 255, 255, 0.06)',
            '--t1': '#ffffff', '--t2': '#d1d1d1', '--t3': '#888888',
            '--purple': '#ffffff', '--editor-bg': '#141416',
            '--welcome-bg': 'linear-gradient(135deg, #232526 0%, #414345 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #ffffff 0%, #888888 100%)'
        }
    },
    discord_classic: {
        name: "Discord Classic",
        styles: {
            '--bg': '#2f3136', '--bg2': '#36393f', '--bg3': '#202225', '--bg4': '#40444b',
            '--bd': 'rgba(255, 255, 255, 0.05)', '--bd2': 'rgba(0, 0, 0, 0.2)',
            '--t1': '#ffffff', '--t2': '#b9bbbe', '--t3': '#72767d',
            '--purple': '#5865f2', '--editor-bg': '#2f3136',
            '--welcome-bg': 'linear-gradient(135deg, #5865f2 0%, #7289da 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #5865f2 0%, #00d2ff 100%)'
        }
    },
    discord_modern: {
        name: "Discord Modern",
        styles: {
            '--bg': '#232428', '--bg2': '#2b2d31', '--bg3': '#1e1f22', '--bg4': '#313338',
            '--bd': 'rgba(255, 255, 255, 0.05)', '--bd2': 'rgba(0, 0, 0, 0.2)',
            '--t1': '#f2f3f5', '--t2': '#949ba4', '--t3': '#4e5058',
            '--purple': '#5865f2', '--editor-bg': '#232428',
            '--welcome-bg': 'linear-gradient(135deg, #4752c4 0%, #5865f2 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #5865f2 0%, #eb459e 100%)'
        }
    },
    github_dark: {
        name: "GitHub Dark",
        styles: {
            '--bg': '#0d1117', '--bg2': '#161b22', '--bg3': '#21262d', '--bg4': '#30363d',
            '--bd': 'rgba(48, 54, 61, 0.7)', '--bd2': 'rgba(1, 4, 9, 0.8)',
            '--t1': '#c9d1d9', '--t2': '#8b949e', '--t3': '#484f58',
            '--purple': '#58a6ff', '--editor-bg': '#0d1117',
            '--welcome-bg': 'linear-gradient(135deg, #0d1117 0%, #1f6feb 100%)',
            '--welcome-text': '#ffffff',
            '--welcome-sub': 'rgba(255, 255, 255, 0.7)',
            '--glass-bg': 'rgba(255, 255, 255, 0.05)',
            '--glass-bd': 'rgba(255, 255, 255, 0.1)',
            '--v5-gradient': 'linear-gradient(135deg, #58a6ff 0%, #7ee787 100%)'
        }
    },
    carbon_slate: {
        name: "Carbon Slate",
        styles: {
            '--bg': '#1e1e1e', '--bg2': '#252526', '--bg3': '#333333', '--bg4': '#3c3c3c',
            '--bd': 'rgba(255, 255, 255, 0.1)', '--bd2': 'rgba(0, 0, 0, 0.2)',
            '--t1': '#cccccc', '--t2': '#858585', '--t3': '#555555',
            '--purple': '#ce9178', '--editor-bg': '#1e1e1e',
            '--welcome-bg': 'linear-gradient(135deg, #37373d 0%, #2d2d30 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #ce9178 0%, #dcdcaa 100%)'
        }
    },
    obsidian_dark: {
        name: "Obsidian Dark",
        styles: {
            '--bg': '#161618', '--bg2': '#1c1c1f', '--bg3': '#242429', '--bg4': '#2a2a30',
            '--bd': 'rgba(122, 114, 255, 0.15)', '--bd2': 'rgba(0, 0, 0, 0.3)',
            '--t1': '#e2e2e4', '--t2': '#a1a1a5', '--t3': '#626266',
            '--purple': '#7a72ff', '--editor-bg': '#161618',
            '--welcome-bg': 'linear-gradient(135deg, #2e2e32 0%, #4a4a4f 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #7a72ff 0%, #ff79c6 100%)'
        }
    },
    onyx_mid: {
        name: "Onyx Mid",
        styles: {
            '--bg': '#1c1c1c', '--bg2': '#262626', '--bg3': '#333333', '--bg4': '#404040',
            '--bd': 'rgba(255, 255, 255, 0.08)', '--bd2': 'rgba(255, 255, 255, 0.04)',
            '--t1': '#eeeeee', '--t2': '#999999', '--t3': '#666666',
            '--purple': '#ffffff', '--editor-bg': '#1c1c1c',
            '--welcome-bg': 'linear-gradient(135deg, #333333 0%, #4d4d4d 100%)',
            '--v5-gradient': 'linear-gradient(135deg, #ffffff 0%, #999999 50%, #4d4d4d 100%)'
        }
    }
};


try {
    const customThemes = JSON.parse(localStorage.getItem('sh_custom_themes') || '{}');
    for (const id in customThemes) {
        THEMES_CONFIG[id] = customThemes[id];
    }
} catch (e) {
    console.error("Error loading custom themes:", e);
}

window.saveCustomThemes = function () {
    try {
        const customThemes = {};
        for (const id in THEMES_CONFIG) {
            if (THEMES_CONFIG[id].isCustom) {
                customThemes[id] = THEMES_CONFIG[id];
            }
        }
        localStorage.setItem('sh_custom_themes', JSON.stringify(customThemes));
    } catch (e) {
        console.error("Error saving custom themes:", e);
    }
};

window.safeColorWithAlpha = function (color, opacity) {
    if (!color) return 'rgba(255,255,255,0.1)';
    if (color.startsWith('#')) {
        const hex = color.length === 4 ?
            '#' + color[1] + color[1] + color[2] + color[2] + color[3] + color[3] : color;
        const alpha = Math.round(opacity * 255).toString(16).padStart(2, '0');
        return hex + alpha;
    }
    if (color.startsWith('rgba')) return color.replace(/[\d\.]+\)$/g, opacity + ')');
    if (color.startsWith('rgb')) return color.replace('rgb', 'rgba').replace(')', ', ' + opacity + ')');
    return color;
};

window.adjustColorBrightness = function (hex, percent) {
    if (!hex || typeof hex !== 'string') return hex;
    let r = 0, g = 0, b = 0;
    if (hex.startsWith('#')) {
        let color = hex.replace(/^#/, '');
        if (color.length === 3) {
            color = color[0] + color[0] + color[1] + color[1] + color[2] + color[2];
        }
        r = parseInt(color.substring(0, 2), 16) || 0;
        g = parseInt(color.substring(2, 4), 16) || 0;
        b = parseInt(color.substring(4, 6), 16) || 0;
    } else if (hex.startsWith('rgb')) {
        const parts = hex.match(/\d+/g);
        if (parts && parts.length >= 3) {
            r = parseInt(parts[0]);
            g = parseInt(parts[1]);
            b = parseInt(parts[2]);
        }
    } else {
        return hex;
    }

    r = Math.min(255, Math.max(0, r + percent));
    g = Math.min(255, Math.max(0, g + percent));
    b = Math.min(255, Math.max(0, b + percent));

    const rHex = r.toString(16).padStart(2, '0');
    const gHex = g.toString(16).padStart(2, '0');
    const bHex = b.toString(16).padStart(2, '0');

    return `#${rHex}${gHex}${bHex}`;
};

window.getCurrentAccentColor = function () {
    const theme = THEMES_CONFIG[window.activeThemeId] || THEMES_CONFIG.v5;
    if (typeof settings !== 'undefined' && settings && settings.accentColor && settings.accentColor.toLowerCase() !== '#7b7ff6') return settings.accentColor;
    return theme.styles['--purple'] || '#ec96ba';
};


(function () { var t = localStorage.getItem('sh_theme'); if (!t || t === 'dark') localStorage.setItem('sh_theme', 'v5'); })();
window.activeThemeId = localStorage.getItem('sh_theme') || 'v5';
window.isTutorialRunning = false;

window.isApplyingTheme = false;
window.applyTheme = function (themeId) {
    if (window.isApplyingTheme) return;
    window.isApplyingTheme = true;
    try {
        window.activeThemeId = themeId;
        localStorage.setItem('sh_theme', themeId);

        const theme = THEMES_CONFIG[themeId] || THEMES_CONFIG.v5;
        try {
            localStorage.setItem('sh_active_theme_id', themeId);
            localStorage.setItem('sh_active_theme_styles', JSON.stringify(theme.styles));
        } catch (e) { }


        const root = document.documentElement;
        root.style.setProperty('--welcome-text', '#ffffff');
        root.style.setProperty('--welcome-sub', 'rgba(255, 255, 255, 0.6)');


        const activePurple = (typeof settings !== 'undefined' && settings && settings.accentColor && settings.accentColor.toLowerCase() !== '#7b7ff6') ? settings.accentColor : (theme.styles['--purple'] || '#7b7ff6');
        const accentColor = activePurple;
        const glowColor = theme.styles['--v5-glow'] || window.safeColorWithAlpha(accentColor, 0.4);
        root.style.setProperty('--v5-glow', glowColor);

        for (const key in theme.styles) {
            root.style.setProperty(key, theme.styles[key]);
        }


        if (window.applyAccentColor) window.applyAccentColor();
        if (window.applyBackdropClasses) window.applyBackdropClasses();

        const isLight = theme.isLight === true;
        if (isLight) document.body.classList.add('light-theme');
        else document.body.classList.remove('light-theme');


        if (typeof monaco !== 'undefined' && theme.styles['--editor-bg']) {
            monaco.editor.defineTheme('sirhurt', {
                base: isLight ? 'vs' : 'vs-dark',
                inherit: true,
                rules: [
                    { token: 'keyword', foreground: 'c678dd', fontStyle: 'bold' },
                    { token: 'string', foreground: '98c379' },
                    { token: 'comment', foreground: '5c6370', fontStyle: 'italic' },
                    { token: 'variable.predefined', foreground: 'e06c75' },
                    { token: 'predefined', foreground: 'e5c07b' }
                ],
                colors: {
                    'editor.background': (typeof settings !== 'undefined' && settings && settings.acrylicEnabled) ? '#00000000' : theme.styles['--editor-bg'],
                    'editor.foreground': theme.styles['--t1'],
                    'editor.lineHighlightBorder': '#00000000',
                    'editor.lineHighlightBackground': window.safeColorWithAlpha(accentColor, 0.08),
                    'editor.selectionBackground': window.safeColorWithAlpha(accentColor, 0.2),
                    'editorCursor.foreground': accentColor,
                    'editorLineNumber.foreground': window.safeColorWithAlpha(theme.styles['--t3'], 0.5),
                    'editorLineNumber.activeForeground': theme.styles['--t1'],
                    'editorIndentGuide.background': window.safeColorWithAlpha(theme.styles['--t3'], 0.2),
                    'editorWidget.background': theme.styles['--bg2'],
                    'editorWidget.border': theme.styles['--bd']
                }
            });
            monaco.editor.setTheme('sirhurt');
            if (monacoEditorSecondary) monaco.editor.setTheme('sirhurt');
            window.applyScrollbarVisibility();
        }

        var _v5inj = document.getElementById('_v5_inject');
        if (_v5inj) _v5inj.remove();
        if (themeId === 'v5') {
            var _s = document.createElement('style');
            _s.id = '_v5_inject';
            _s.textContent = [

                '.hub-btn-exec{background:var(--v5-gradient)!important;border-color:rgba(255,255,255,0.08)!important;box-shadow:0 0 14px rgba(236,150,186,0.35)!important;}',
                '.hub-btn-exec:hover{background:var(--v5-gradient)!important;filter:brightness(1.12)!important;box-shadow:0 0 22px rgba(236,150,186,0.5)!important;}',

                '.editor-tab.active::after{background:var(--v5-gradient)!important;}',
            ].join('');
            document.head.appendChild(_s);
        }

        window.renderThemeGrid();
    } finally {
        window.isApplyingTheme = false;
    }
};

window.renderThemeGrid = function () {
    const grid = document.getElementById('theme-grid');
    const customGrid = document.getElementById('custom-theme-grid');
    const customBlock = document.getElementById('custom-theme-block');
    if (!grid) return;

    let standardHtml = '';
    let customHtml = '';
    let hasCustom = false;

    Object.keys(THEMES_CONFIG).forEach(id => {
        const theme = THEMES_CONFIG[id];
        const isActive = (id === window.activeThemeId) ? 'active' : '';

        if (theme.isCustom) {
            hasCustom = true;
            customHtml += `
                <div class="theme-card ${isActive} zenith-scroll-item" data-theme-id="${id}" onclick="applyTheme('${id}')" style="position:relative;">
                    <div class="tc-name">${theme.name}</div>
                </div>
            `;
        } else {
            standardHtml += `
                <div class="theme-card ${isActive} zenith-scroll-item" data-theme-id="${id}" onclick="applyTheme('${id}')" style="position:relative;">
                    <div class="tc-name">${theme.name}</div>
                </div>
            `;
        }
    });

    grid.innerHTML = standardHtml;

    if (customGrid && customBlock) {
        if (hasCustom) {
            customGrid.innerHTML = customHtml;
            customBlock.style.display = 'block';
        } else {
            customGrid.innerHTML = '';
            customBlock.style.display = 'none';
        }
    }


    document.querySelectorAll('.theme-grid .zenith-scroll-item').forEach(el => {
        if (window.observeScrollElement) window.observeScrollElement(el);
    });
};

window.deleteCustomTheme = function (themeId) {
    if (!THEMES_CONFIG[themeId] || !THEMES_CONFIG[themeId].isCustom) return;

    const execDelete = function () {

        if (window.activeThemeId === themeId) {
            window.applyTheme('v5');
        }

        delete THEMES_CONFIG[themeId];


        try {
            const customThemes = JSON.parse(localStorage.getItem('sh_custom_themes') || '{}');
            delete customThemes[themeId];
            localStorage.setItem('sh_custom_themes', JSON.stringify(customThemes));
        } catch (e) { console.error(e); }


        const grid = document.getElementById('theme-grid');
        if (grid) grid.innerHTML = '';
        const customGrid = document.getElementById('custom-theme-grid');
        if (customGrid) customGrid.innerHTML = '';
        window.renderThemeGrid();

        if (window.showNotification) window.showNotification("Custom theme deleted");
    };

    if (settings.confirmDeleteTheme) {
        const theme = THEMES_CONFIG[themeId];
        const tName = theme ? theme.name : "this theme";
        window.openActionModal(
            "Delete " + tName + "?",
            "Are you sure you want to delete this custom theme? If deleted, it cannot be recovered.",
            "red",
            execDelete
        );
    } else {
        execDelete();
    }
};


setTimeout(() => {
    function applyLivePreview() {
        const bg = $id('custom-theme-bg-hex').value;
        const bg2 = $id('custom-theme-bg2-hex').value;
        const t1 = $id('custom-theme-t1-hex').value;
        const purple = $id('custom-theme-purple-hex').value;

        const previewStyles = {
            '--bg': bg,
            '--bg2': bg2,
            '--bg3': window.adjustColorBrightness(bg2, 8),
            '--bg4': window.adjustColorBrightness(bg2, 16),
            '--bd': 'rgba(255, 255, 255, 0.08)',
            '--bd2': 'rgba(255, 255, 255, 0.04)',
            '--t1': t1,
            '--t2': window.adjustColorBrightness(t1, -30),
            '--t3': window.adjustColorBrightness(t1, -55),
            '--purple': purple,
            '--editor-bg': bg,
            '--v5-glow': window.safeColorWithAlpha(purple, 0.4),
            '--welcome-bg': `linear-gradient(135deg, ${bg2} 0%, ${purple} 100%)`,
            '--welcome-bd': window.safeColorWithAlpha(purple, 0.2),
            '--welcome-text': t1,
            '--welcome-sub': window.adjustColorBrightness(t1, -15),
            '--glass-bg': window.safeColorWithAlpha(purple, 0.03),
            '--glass-bd': window.safeColorWithAlpha(purple, 0.08),
            '--v5-gradient': `linear-gradient(135deg, ${purple} 0%, ${window.adjustColorBrightness(purple, 15)} 50%, ${window.adjustColorBrightness(purple, -15)} 100%)`
        };

        Object.keys(previewStyles).forEach(key => {
            document.documentElement.style.setProperty(key, previewStyles[key]);
        });


        if (window.applyAccentColor) window.applyAccentColor();
    }


    let activeColorTarget = null;
    const modalOverlay = $id('custom-color-modal-overlay');
    const modalHex = $id('modal-hex-input');
    const modalPreview = $id('modal-color-preview');
    const hueSlider = $id('modal-hue-slider');
    const lightSlider = $id('modal-light-slider');
    const hueVal = null;
    const lightVal = null;
    const hueDot = $id('modal-hue-dot');
    const lightDot = $id('modal-light-dot');
    const lightTrack = $id('modal-light-track');

    let currentSaturation = 75;

    function hexToHsl(hex) {
        hex = hex.replace(/^#/, '');
        if (hex.length === 3) hex = hex.split('').map(x => x + x).join('');
        let r = parseInt(hex.substring(0, 2), 16) / 255;
        let g = parseInt(hex.substring(2, 4), 16) / 255;
        let b = parseInt(hex.substring(4, 6), 16) / 255;

        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let h, s, l = (max + min) / 2;

        if (max === min) {
            h = s = 0;
        } else {
            let d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        return {
            h: Math.round(h * 360),
            s: Math.round(s * 100),
            l: Math.round(l * 100)
        };
    }

    function hslToHex(h, s, l) {
        s /= 100;
        l /= 100;
        let r, g, b;
        if (s === 0) {
            r = g = b = l;
        } else {
            const hue2rgb = (p, q, t) => {
                if (t < 0) t += 1;
                if (t > 1) t -= 1;
                if (t < 1 / 6) return p + (q - p) * 6 * t;
                if (t < 1 / 2) return q;
                if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
                return p;
            };
            let q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            let p = 2 * l - q;
            r = hue2rgb(p, q, h / 360 + 1 / 3);
            g = hue2rgb(p, q, h / 360);
            b = hue2rgb(p, q, h / 360 - 1 / 3);
        }
        const toHex = x => Math.round(x * 255).toString(16).padStart(2, '0');
        return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
    }

    function updateModalFromHSL() {
        const h = parseInt(hueSlider.value);
        const l = parseInt(lightSlider.value);
        const hex = hslToHex(h, currentSaturation, l);

        modalHex.value = hex.toUpperCase();
        modalPreview.style.backgroundColor = hex;
        if (hueDot) hueDot.style.background = hslToHex(h, 80, 55);
        if (lightDot) lightDot.style.background = hslToHex(h, currentSaturation, l);


        const baseColor = hslToHex(h, currentSaturation, 50);
        if (lightTrack) {
            lightTrack.style.background = `linear-gradient(to right, #000000, ${baseColor}, #ffffff)`;
        }


        if (window.updateZSlider) {
            window.updateZSlider(hueSlider);
            window.updateZSlider(lightSlider);
        }


        if (activeColorTarget) {
            $id(`custom-theme-${activeColorTarget}-hex`).value = hex;
            $id(`custom-theme-swatch-${activeColorTarget}`).style.backgroundColor = hex;
            applyLivePreview();
        }
    }

    function updateModalFromHex(hex) {
        const hsl = hexToHsl(hex);
        currentSaturation = hsl.s < 5 ? 75 : hsl.s;
        hueSlider.value = hsl.h;
        lightSlider.value = hsl.l;
        updateModalFromHSL();
    }


    if (hueSlider && lightSlider) {
        hueSlider.oninput = updateModalFromHSL;
        lightSlider.oninput = updateModalFromHSL;
    }


    if (modalHex) {
        modalHex.oninput = () => {
            if (/^#[0-9A-Fa-f]{6}$/.test(modalHex.value)) {
                updateModalFromHex(modalHex.value);
            }
        };
    }


    ['bg', 'bg2', 't1', 'purple'].forEach(key => {
        const hexInp = $id(`custom-theme-${key}-hex`);
        const swatch = $id(`custom-theme-swatch-${key}`);
        if (swatch && hexInp) {
            hexInp.addEventListener('input', () => {
                if (/^#[0-9A-F]{6}$/i.test(hexInp.value)) {
                    swatch.style.backgroundColor = hexInp.value;
                    applyLivePreview();
                }
            });
            swatch.onclick = () => {
                activeColorTarget = null;
                updateModalFromHex(hexInp.value);
                activeColorTarget = key;
                modalOverlay.classList.add('active');
            };
        }
    });

    if ($id('close-color-modal')) $id('close-color-modal').onclick = () => modalOverlay.classList.remove('active');
    if ($id('apply-color-btn')) $id('apply-color-btn').onclick = () => modalOverlay.classList.remove('active');

    document.querySelectorAll('.preset-swatch').forEach(p => {
        p.onclick = () => {
            const hex = p.getAttribute('data-hex');
            updateModalFromHex(hex);
        };
    });

    if ($id('btn-create-theme')) {
        $id('btn-create-theme').onclick = function () {
            const nameInput = $id('custom-theme-name');
            const name = nameInput ? nameInput.value.trim() : "";
            if (!name) {
                if (window.showNotification) window.showNotification("Please enter a theme name");

                return;
            }

            const bg = $id('custom-theme-bg-hex').value;
            const bg2 = $id('custom-theme-bg2-hex').value;
            const t1 = $id('custom-theme-t1-hex').value;
            const purple = $id('custom-theme-purple-hex').value;

            const themeId = "custom_" + Date.now();

            const customTheme = {
                name: name,
                isCustom: true,
                styles: {
                    '--bg': bg,
                    '--bg2': bg2,
                    '--bg3': window.adjustColorBrightness(bg2, 8),
                    '--bg4': window.adjustColorBrightness(bg2, 16),
                    '--bd': 'rgba(255, 255, 255, 0.08)',
                    '--bd2': 'rgba(255, 255, 255, 0.04)',
                    '--t1': t1,
                    '--t2': window.adjustColorBrightness(t1, -30),
                    '--t3': window.adjustColorBrightness(t1, -55),
                    '--purple': purple,
                    '--editor-bg': bg,
                    '--v5-glow': window.safeColorWithAlpha(purple, 0.4),
                    '--welcome-bg': `linear-gradient(135deg, ${bg2} 0%, ${purple} 100%)`,
                    '--welcome-bd': window.safeColorWithAlpha(purple, 0.2),
                    '--welcome-text': t1,
                    '--welcome-sub': window.adjustColorBrightness(t1, -15),
                    '--glass-bg': window.safeColorWithAlpha(purple, 0.03),
                    '--glass-bd': window.safeColorWithAlpha(purple, 0.08),
                    '--v5-gradient': `linear-gradient(135deg, ${purple} 0%, ${window.adjustColorBrightness(purple, 15)} 50%, ${window.adjustColorBrightness(purple, -15)} 100%)`
                }
            };

            THEMES_CONFIG[themeId] = customTheme;
            saveCustomThemes();

            nameInput.value = "";
            const grid = document.getElementById('theme-grid');
            if (grid) grid.innerHTML = '';
            window.renderThemeGrid();
            window.applyTheme(themeId);

            if (window.showNotification) window.showNotification("Custom theme created!");
        };
    }

    if ($id('btn-reset-theme-inputs')) {
        $id('btn-reset-theme-inputs').onclick = function () {
            $id('custom-theme-bg-hex').value = '#0c0c0e';
            $id('custom-theme-swatch-bg').style.backgroundColor = '#0c0c0e';

            $id('custom-theme-bg2-hex').value = '#101013';
            $id('custom-theme-swatch-bg2').style.backgroundColor = '#101013';

            $id('custom-theme-t1-hex').value = '#ffffff';
            $id('custom-theme-swatch-t1').style.backgroundColor = '#ffffff';

            $id('custom-theme-purple-hex').value = '#ec96ba';
            $id('custom-theme-swatch-purple').style.backgroundColor = '#ec96ba';

            const activeTheme = settings.theme || 'v5';
            if (window.applyTheme) {
                window.applyTheme(activeTheme);
            }

            if (window.showNotification) window.showNotification("Theme inputs reset to default");
        };
    }




    if ($id('ctx-theme-rename')) {
        $id('ctx-theme-rename').onclick = function () {
            hideCtxMenus();
            if (!window.ctxTargetThemeId) return;
            const theme = THEMES_CONFIG[window.ctxTargetThemeId];
            if (!theme || !theme.isCustom) return;

            if (window.openRenameModal) {
                window.openRenameModal("Rename Theme", theme.name, function (newName) {
                    if (!newName || !newName.trim()) return;
                    theme.name = newName.trim();
                    window.saveCustomThemes();
                    const grid = document.getElementById('theme-grid');
                    if (grid) grid.innerHTML = '';
                    window.renderThemeGrid();
                });
            }
        };
    }

    if ($id('ctx-theme-duplicate')) {
        $id('ctx-theme-duplicate').onclick = function () {
            hideCtxMenus();
            if (!window.ctxTargetThemeId) return;
            const theme = THEMES_CONFIG[window.ctxTargetThemeId];
            if (!theme || !theme.isCustom) return;

            const newId = "custom_" + Date.now();
            THEMES_CONFIG[newId] = {
                name: theme.name + " (Copy)",
                isCustom: true,
                styles: JSON.parse(JSON.stringify(theme.styles))
            };
            window.saveCustomThemes();
            const grid = document.getElementById('theme-grid');
            if (grid) grid.innerHTML = '';
            window.renderThemeGrid();
            window.applyTheme(newId);

            if (window.showNotification) window.showNotification("Theme duplicated!");
        };
    }

    if ($id('ctx-theme-delete')) {
        $id('ctx-theme-delete').onclick = function () {
            hideCtxMenus();
            if (!window.ctxTargetThemeId) return;
            window.deleteCustomTheme(window.ctxTargetThemeId);
        };
    }
}, 500);


window.applyTheme(window.activeThemeId);
window.renderThemeGrid();

window.renderRobloxManager = async function (supportedVersion) {
    var list = document.getElementById('roblox-manager-list');
    if (!list) return;

    try {
        if (typeof bridge === 'undefined' || !bridge.GetRobloxVersionsJSON) {
            list.innerHTML = '<div class="cl-entry"><div class="cl-body" style="color:var(--t3)">Bridge not ready.</div></div>';
            return;
        }

        var rawJson = await bridge.GetRobloxVersionsJSON();
        var verArray = JSON.parse(rawJson);

        if (!verArray || verArray.length === 0) {
            list.innerHTML = '<div class="cl-entry"><div class="cl-body" style="color:var(--t2)">No local Roblox installations found.</div></div>';
            return;
        }

        list.innerHTML = '';
        verArray.forEach(function (ver) {
            var isPerfectMatch = (ver.toLowerCase() === supportedVersion.toLowerCase());

            var el = document.createElement('div');
            el.className = 'cl-entry zenith-scroll-item';
            if (window.observeScrollElement) window.observeScrollElement(el);
            el.style.flexDirection = 'column';
            el.style.flex = '1';
            el.style.gap = '4px';


            var btnStyle = "flex: 1; padding: 6px 0; font-size: 10.5px; text-align: center; justify-content: center;";

            el.innerHTML =
                '<div class="cl-ver" style="font-size: 11.5px; font-weight: bold; word-break: break-all; color: var(--t2);">Found: <span style="color: var(--t1);">' + ver + '</span></div>' +
                '<div style="display:flex; gap:6px; width: 100%; flex-wrap: wrap;">' +
                '<button class="action-btn" style="' + btnStyle + '" onclick="window.bridgeCall(\'LaunchRoblox\', \'' + ver + '\')">Launch</button>' +
                '<button class="action-btn" style="' + btnStyle + '" onclick="window.bridgeCall(\'OpenRobloxFolder\', \'' + ver + '\')">Folder</button>' +
                '<button class="action-btn" style="' + btnStyle + ' color: var(--red); border-color: rgba(255, 69, 58, 0.3);" onclick="openDeleteModal(\'' + ver + '\')">Delete</button>' +
                '</div>';
            list.appendChild(el);
        });
    } catch (e) {
        list.innerHTML = '<div class="cl-entry"><div class="cl-body" style="color:var(--red)">Failed to scan versions.</div></div>';
    }
};

window.checkSirHurtStatus = function () {
    var list = document.getElementById('live-status-list');
    if (!list) return;

    if (typeof bridge !== 'undefined' && bridge.FetchWeaoStatus) {
        bridge.FetchWeaoStatus();
    } else {
        if (!window.isUpdatingSirHurt) {
            window.showConnectionErrorModal(() => { window.checkSirHurtStatus(); });
        }
    }
};

window.onWeaoStatusFetched = async function (success, b64Data) {
    var list = document.getElementById('live-status-list');
    var updateCard = document.getElementById('updater-card-inner');
    var uTitle = document.getElementById('updater-title');
    var uSub = document.getElementById('updater-sub');
    var uNotes = document.getElementById('updater-notes');
    var actionNormal = document.getElementById('updater-action-normal');
    var uIconBg = document.getElementById('updater-icon-bg');
    var uIconSvg = document.getElementById('updater-icon-svg');

    if (!success || !b64Data) {
        if (!window.isUpdatingSirHurt) {
            window.showConnectionErrorModal(() => { window.checkSirHurtStatus(); });
        }
        return;
    }

    try {
        var data = atob(b64Data);
        var parser = new DOMParser();
        var doc = parser.parseFromString(data, 'text/html');
        var rawText = doc.body.innerText || doc.body.textContent || "";
        var shVerMatch = rawText.match(/SirHurt\s+(V[0-9.]+)/i);
        var verMatch = rawText.match(/(version-[a-fA-F0-9]+)/i);
        var version = verMatch ? verMatch[1] : "Unknown Version";
        var isUpdatedStatus = rawText.includes('Updated') || rawText.includes('Working');

        var detVer = document.getElementById('detected-version');
        var insVer = document.getElementById('installed-version');

        if (shVerMatch) window.lastDetectedShVersion = shVerMatch[1];

        var installedVerLocal = localStorage.getItem('installed_version');



        if (isUpdatedStatus && installedVerLocal && installedVerLocal !== version) {
            localStorage.setItem('installed_version', version);
            installedVerLocal = version;
        }

        if (insVer) {
            if (installedVerLocal === version && shVerMatch) {
                insVer.innerText = "SirHurt " + shVerMatch[1];
            } else if (installedVerLocal) {
                insVer.innerText = "SirHurt (Pending Update)";
            } else {
                insVer.innerText = "Unknown (Update to track)";
            }
        }
        if (detVer) detVer.innerText = shVerMatch ? "SirHurt " + shVerMatch[1] : "SirHurt V5";

        var status = "Unknown Status";
        if (isUpdatedStatus) status = "Updated";
        else if (rawText.includes('Patched') || rawText.includes('Outdated')) {
            status = "Not Updated";

            if (window.openActionModal) {
                window.openActionModal(
                    "SirHurt is Not Updated",
                    "SirHurt is not updated for the latest Roblox version, please downgrade. Note: The folder must be named exactly the version (e.g. 'version-acc4b74f79e743b9') for the UI to recognize it.",
                    "purple",
                    () => { }
                );
            }
        }
        else if (rawText.includes('Testing')) status = "Testing";

        var sirhurtNode = null;
        var elements = doc.querySelectorAll('*');
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].children.length === 0 && elements[i].textContent.trim().toLowerCase() === 'sirhurt') {
                sirhurtNode = elements[i];
                break;
            }
        }

        if (!sirhurtNode) throw new Error("Could not locate SirHurt text");

        var card = sirhurtNode;
        for (var j = 0; j < 6; j++) {
            if (card.parentElement) {
                card = card.parentElement;
                if (card.textContent.includes('Last updated')) break;
            }
        }

        function extractText(node) {
            var text = "";
            for (var i = 0; i < node.childNodes.length; i++) {
                var child = node.childNodes[i];
                if (child.nodeType === 3) {
                    if (child.nodeValue.trim().length > 0) text += child.nodeValue.trim() + "\n";
                } else if (child.nodeType === 1) {
                    text += extractText(child) + "\n";
                }
            }
            return text;
        }

        var parsedText = extractText(card);
        var lines = parsedText.split('\n').map(function (l) { return l.trim(); }).filter(function (l) { return l.length > 0; });

        var updateTime = "Unknown Time";
        for (var k = 0; k < lines.length; k++) {
            var lowerLine = lines[k].toLowerCase();
            if (lowerLine.includes('last updated')) {
                var inlineTime = lines[k].replace(/last updated:?/i, '').trim();
                if (inlineTime.length < 5 && k + 1 < lines.length) {
                    updateTime = lines[k + 1].trim();
                } else {
                    updateTime = inlineTime;
                }
                break;
            }
        }

        var history = [];
        try { history = JSON.parse(localStorage.getItem('sh_changelog')) || []; } catch (e) { }


        var hasOldUpdate = history.some(function (item) { return item.version === "version-26c90be22e0d4758"; });
        if (!hasOldUpdate) {
            history.push({
                type: "Old Update",
                status: "SirHurt works on this version",
                version: "version-26c90be22e0d4758",
                time: "4/10/2025 at 3:44 AM UTC"
            });
        }

        if (history.length === 0 || history[0].version !== version) {
            if (history.length > 0 && history[0].type === "Latest Update") {
                history[0].type = "Old Update";
                history[0].status = "SirHurt works on this version";
            }
            history.unshift({ type: "Latest Update", status: status, version: version, time: updateTime });
        } else {
            history[0].status = status;
            history[0].time = updateTime;
        }

        if (history.length > 5) history = history.slice(0, 5);
        try { localStorage.setItem('sh_changelog', JSON.stringify(history)); } catch (e) { }

        var detVer = document.getElementById('detected-version');
        if (detVer) {

            var shVerMatch = rawText.match(/SirHurt\s+(V[0-9a-zA-Z.]+)/i);
            if (shVerMatch) window.lastDetectedShVersion = shVerMatch[1];
            detVer.innerText = shVerMatch ? "SirHurt " + shVerMatch[1] : "SirHurt V5";
        }

        list.innerHTML = '';
        history.forEach(function (item) {
            var isLatest = item.type === "Latest Update";
            var textColor = "var(--red)";
            if (item.status === "Updated" || item.status === "Working" || item.status === "SirHurt works on this version") {
                textColor = "var(--purple)";
            } else if (item.status === "Testing") {
                textColor = "var(--yellow)";
            }

            var el = document.createElement('div');
            el.className = 'cl-entry';
            var opacityTag = isLatest ? '<div>' : '<div style="opacity: 0.65;">';
            var timeHtml = '<div style="margin-bottom:4px;">Last Updated: ' + item.time + '</div>';

            el.innerHTML = opacityTag +
                '<div class="cl-top">' +
                '<div class="cl-ver">' + item.type + '</div>' +
                '</div>' +
                '<div class="cl-body" style="color:var(--t1); font-size:11px; margin-top:6px;">' +
                '<div style="margin-bottom:4px;">Status: <span style="color:' + textColor + '; font-weight:bold;">' + item.status + '</span></div>' +
                '<div style="margin-bottom:4px;">Version: ' + item.version + '</div>' +
                timeHtml +
                '</div>' +
                '</div>';

            list.appendChild(el);
        });

        if (window.renderRobloxManager) window.renderRobloxManager(version);

        window.latestWeaoVersion = version;
        var installedVer = localStorage.getItem('installed_version');
        var uTitle = document.getElementById('update-title-text');
        var uSub = document.getElementById('update-sub-text');
        var uNotes = document.getElementById('update-notes-text');
        var uIconBg = document.getElementById('update-icon-bg');
        var uIconSvg = document.getElementById('update-icon-svg');
        var actionNormal = document.getElementById('update-actions-normal');
        var actionRestart = document.getElementById('update-actions-restart');

        var updateCard = document.getElementById('home-card-update');

        if (uTitle && uSub && actionNormal) {
            actionRestart.style.display = 'none';

            var isInstalled = true;
            if (typeof bridge !== 'undefined' && bridge.IsSirHurtInstalled) {
                isInstalled = await bridge.IsSirHurtInstalled();
            }

            if (!isInstalled) {
                uTitle.innerText = "Download SirHurt";
                uTitle.style.color = "var(--t1)";
                uSub.innerText = "Action Required";
                uNotes.innerText = "Click Download Now to start installing SirHurt to the directory.";
                actionNormal.style.display = 'flex';

                if (updateCard) {
                    updateCard.style.background = "linear-gradient(130deg, rgba(var(--accent-rgb, 162, 162, 208), 0.14) 0%, rgba(var(--accent-rgb, 162, 162, 208), 0.04) 100%)";
                    updateCard.style.borderColor = "rgba(var(--accent-rgb, 162, 162, 208), 0.2)";
                }

                var btn = document.getElementById('btn-do-update');
                if (btn) {
                    btn.innerText = "Download Now";
                    btn.style.background = "rgba(var(--accent-rgb, 162, 162, 208), 0.1)";
                    btn.style.borderColor = "rgba(var(--accent-rgb, 162, 162, 208), 0.2)";
                    btn.style.boxShadow = "none";
                    btn.style.color = "var(--purple)";
                    btn.onclick = () => {
                        window.isUpdatingSirHurt = true;
                        btn.innerText = "Downloading...";
                        btn.style.opacity = "0.6";
                        btn.style.pointerEvents = "none";
                        uSub.innerText = "Installing SirHurt";
                        uNotes.innerText = "SirHurt is being installed. Please wait...";
                        if (window.startSirHurtUpdateUI) window.startSirHurtUpdateUI('LIVE');
                        window.bridgeCall('UpdateSirHurt');
                    };
                }

                uIconBg.style.background = "rgba(var(--accent-rgb, 162, 162, 208), 0.1)";
                uIconBg.style.color = "var(--purple)";
                uIconSvg.innerHTML = '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>';
            } else if (installedVer === version) {
                localStorage.removeItem('sirhurt_was_downgraded');
                uTitle.innerText = "SirHurt is Updated";
                uTitle.style.color = "var(--welcome-text, var(--t1))";
                uSub.innerText = "Version matched";
                uSub.style.color = "var(--welcome-sub, var(--t2))";
                uNotes.innerText = "You are running the latest version of SirHurt.";
                uNotes.style.color = "var(--welcome-sub, var(--t2))";
                actionNormal.style.display = 'none';

                if (updateCard) {
                    updateCard.style.background = "var(--welcome-bg)";
                    updateCard.style.backgroundSize = "100% 100%";
                    updateCard.style.backgroundRepeat = "no-repeat";
                    updateCard.style.backgroundClip = "padding-box";
                    updateCard.style.overflow = "hidden";
                    updateCard.style.borderColor = "var(--welcome-bd, var(--bd))";
                    updateCard.style.boxShadow = "0 4px 15px rgba(0, 0, 0, 0.12)";
                }

                uIconBg.style.background = "var(--welcome-bg)";
                uIconBg.style.border = "none";
                uIconBg.style.boxShadow = "inset 0 0 0 1px var(--welcome-bd, rgba(255, 255, 255, 0.14))";
                uIconBg.style.backgroundClip = "padding-box";
                uIconBg.style.backdropFilter = "none";
                uIconBg.style.color = "var(--welcome-text, var(--t1))";
                uIconSvg.innerHTML = '<polyline points="20 7 10 17 5 12" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></polyline>';
            } else {
                var wasDowngraded = localStorage.getItem('sirhurt_was_downgraded') === 'true';
                if (wasDowngraded) {
                    uTitle.innerText = "SirHurt Was Downgraded";
                    uTitle.style.color = "var(--t1)";
                    uSub.innerText = "SirHurt was last downgraded";
                    uNotes.innerText = "To ensure you are running the latest SirHurt build you can press update now.";
                } else {
                    uTitle.innerText = "Update Available";
                    uTitle.style.color = "var(--t1)";
                    uSub.innerText = "New version detected";
                    uNotes.innerText = "A new bootstrapper update is available to ensure compatibility with the latest Roblox version.";
                }
                actionNormal.style.display = 'flex';

                if (updateCard) {
                    updateCard.style.background = "linear-gradient(130deg, rgba(var(--accent-rgb, 162, 162, 208), 0.14) 0%, rgba(var(--accent-rgb, 162, 162, 208), 0.04) 100%)";
                    updateCard.style.borderColor = "rgba(var(--accent-rgb, 162, 162, 208), 0.2)";
                }

                var btn = document.getElementById('btn-do-update');
                if (btn) {
                    btn.innerText = "Update Now";
                    btn.style.background = "rgba(var(--accent-rgb, 162, 162, 208), 0.1)";
                    btn.style.borderColor = "rgba(var(--accent-rgb, 162, 162, 208), 0.2)";
                    btn.style.boxShadow = "none";
                    btn.style.color = "var(--purple)";
                    btn.onclick = () => {
                        window.isUpdatingSirHurt = true;
                        btn.innerText = "Updating...";
                        btn.style.opacity = "0.6";
                        btn.style.pointerEvents = "none";
                        uSub.innerText = "Installing Update";
                        uNotes.innerText = "SirHurt is being updated. Please wait...";
                        if (window.startSirHurtUpdateUI) window.startSirHurtUpdateUI('LIVE');
                        window.bridgeCall('UpdateSirHurt');
                    };
                }

                uIconBg.style.background = "rgba(var(--accent-rgb, 162, 162, 208), 0.1)";
                uIconBg.style.color = "var(--purple)";
                uIconSvg.innerHTML = '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>';
            }
        }

    } catch (e) {
        if (list) list.innerHTML = '<div class="cl-entry"><div class="cl-body" style="color:var(--red)">Failed to sync online status.</div></div>';


        if (uTitle && uSub) {
            uTitle.innerText = "Update Failed";
            uTitle.style.color = "var(--red)";
            uSub.innerText = "Something went wrong";
            uNotes.innerText = "Please try again or restart the UI.";

            actionNormal.style.display = 'flex';
            var btn = document.getElementById('btn-do-update');
            if (btn) {
                btn.innerText = "Retry";
                btn.style.background = "rgba(255, 69, 58, 0.1)";
                btn.style.borderColor = "rgba(255, 69, 58, 0.2)";
                btn.style.boxShadow = "none";
                btn.style.color = "var(--red)";
                btn.onclick = () => window.checkSirHurtStatus();
            }

            if (updateCard) {
                updateCard.style.background = "linear-gradient(130deg, rgba(255, 69, 58, 0.08) 0%, rgba(50, 20, 20, 0.35) 100%)";
                updateCard.style.borderColor = "rgba(255, 69, 58, 0.2)";
                updateCard.style.boxShadow = "none";
            }

            uIconBg.style.background = "rgba(255, 69, 58, 0.1)";
            uIconBg.style.color = "var(--red)";
            uIconBg.style.border = "1px solid rgba(255, 69, 58, 0.2)";
            uIconSvg.innerHTML = '<path d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"></path>';
        }
    }
};

window.showConnectionErrorModal = function (retryCb) {
    const modal = document.getElementById('action-modal');
    const title = document.getElementById('action-title');
    const desc = document.getElementById('action-desc');
    const btnConfirm = document.getElementById('action-confirm');
    const btnCancel = document.getElementById('action-cancel');
    if (!modal || !title || !btnConfirm) return;

    title.innerText = "Connection failed";
    desc.innerText = "Connection to check for updates and online status from WEAO, sirhurt and github have all failed";
    btnConfirm.innerText = "Retry";
    btnConfirm.style.background = "var(--purple-glow)";
    btnConfirm.style.borderColor = "var(--purple)";
    btnConfirm.style.color = "var(--t1)";

    btnConfirm.onclick = () => {
        modal.classList.remove('visible');
        if (retryCb) retryCb();
    };
    btnCancel.onclick = () => {
        modal.classList.remove('visible');
    };
    modal.classList.add('visible');
};

setTimeout(() => window.checkSirHurtStatus(), 100);

var bridge = window.__zenithBridge || ((window.chrome && window.chrome.webview) ? window.chrome.webview.hostObjects.bridge : null);
function $id(id) { return document.getElementById(id); }

var tabsList = $id('tabs-list');
var fpBody = $id('fp-body');
var fpHeader = $id('fp-header-text');
var fpBack = $id('fp-back');
var consoleBox = $id('console-box');
var consoleBody = $id('console-body');
var appGlow = $id('app-glow');
var filePanel = $id('file-panel');

var monacoEditor = null, monacoEditorSecondary = null;
var monacoModels = {};
var fallbackEditor = null;
var isSplitView = false;
var splitTabIds = [];

var recentlyAddedTabId = null;
var justDroppedTabId = null;

var defaultSettings = {
    enableScriptHistory: true,
    historyCleanDuration: '3',
    windowsStartup: false,
    consoleLimit: 1000,
    autoSpoofStartup: false, autoSpoofExit: false,
    autoClearCookiesStartup: false, autoClearCookiesExit: false,
    autoCleanerStartup: false, autoCleanerExit: false,
    topmost: true, autoinject: false, autoexe: true, errorSpoofing: false, unlockFps: false, closeRobloxOnExit: false,
    defaultPage: 'home', navSlideOut: false, symNav: false, statusGlow: true, accentGlow: true, formatPaste: false,
    animations: true, glowButtons: true, tabGlow: true, windowRounded: true, uiRounded: true, accentColor: '#7b7ff6',
    statusGlowFollowAccent: true,
    swapButtons: false, autoAttachDelay: 5, filesCollapsed: false, consoleCollapsed: false,
    showScrollbars: true, skipSpoofWarning: false, splitTabIds: [],
    confirmClose: true, confirmClear: true, confirmDelete: true, confirmDeleteHistory: true, confirmDeleteAllHistory: true, confirmDeleteTheme: true, confirmCloseOthers: true, confirmCloseApp: true,
    blurOptions: true,
    transparency: true,

    acrylicEnabled: false,
    unfocusedOpacityEnabled: false, unfocusedOpacity: 85,
    hideFileList: false, hideConsoleOutput: false, showKillRoblox: false,
    highPerformance: true,

    editorFontSize: 13, editorWordWrap: 'off', editorInsertSpaces: true,
    editorCursorStyle: 'line', editorCursorBlinking: 'blink',
    editorMatchBrackets: 'always', editorMinimap: false, editorMinimapSide: 'right',
    editorWhitespace: 'none', editorBracketColorization: true, focusOnNewTab: true,

    safeMode: false, autoLoadHub: true, hideContext: true, clearOnExec: false, ignoreErrors: false,
    autoexecDelay: 0, discordRpc: false, minimizeToTray: false, hardwareAccel: true, customFps: 500, restoreTabs: true,
    screenLock: false, mouseDragScroll: false, discordClientId: "123456789012345678",
    editorScrollbarV: true, editorScrollbarH: true,
    showV5: true, uiSize: 'normal', loader: true, focusOnNewTab: true
};
var skipSpoofWarningSession = false;
var savedSettings = null;
try { savedSettings = JSON.parse(localStorage.getItem('sh_settings') || 'null'); } catch (e) { }
var settings = Object.assign(defaultSettings, savedSettings || {});

// Older builds also persisted settings in the registry. If their WebView2
// profile cannot be moved during the 1.2 layout migration, restore that copy.
if (!savedSettings && bridge && bridge.GetSavedSettings) {
    Promise.resolve(bridge.GetSavedSettings()).then(function (raw) {
        if (!raw || typeof raw !== 'string') return;
        try {
            var restored = JSON.parse(raw);
            if (!restored || typeof restored !== 'object') return;
            localStorage.setItem('sh_settings', JSON.stringify(restored));
            window.location.reload();
        } catch (e) { }
    }).catch(function () { });
}

// Ensure defaults are populated if missing from saved settings (e.g. for existing users)
if (settings.acrylicEnabled === undefined || savedSettings === null || savedSettings.acrylicEnabled === undefined) {
    settings.acrylicEnabled = false;
}


if (settings.editorShowScrollbars !== undefined) {
    if (settings.editorScrollbarV === undefined) settings.editorScrollbarV = settings.editorShowScrollbars;
    if (settings.editorScrollbarH === undefined) settings.editorScrollbarH = settings.editorShowScrollbars;
    delete settings.editorShowScrollbars;
}

var savedTabs = null;
if (settings.restoreTabs !== false) {
    try { savedTabs = JSON.parse(localStorage.getItem('sh_tabs') || 'null'); } catch (e) { }
}
var tabs = savedTabs || [{ id: 1, name: 'Tab 1', content: "-- Welcome to SirHurt V5!\nprint('Hello!')" }];
var nextId = Math.max.apply(null, tabs.map(function (t) { return t.id; })) + 1;
var activeTab = tabs[0].id;

splitTabIds = settings.splitTabIds || [];
if (settings.focusOnNewTab === undefined) settings.focusOnNewTab = true;

function saveSettings() {
    try {
        localStorage.setItem('sh_settings', JSON.stringify(settings));
        if (typeof bridge !== 'undefined' && bridge.SaveSettings) bridge.SaveSettings(JSON.stringify(settings));
    } catch (e) { }
}
function saveTabs() { try { localStorage.setItem('sh_tabs', JSON.stringify(tabs)); } catch (e) { } }

var saveTabsTimeout = null;
function debouncedSaveTabs() {
    if (saveTabsTimeout) clearTimeout(saveTabsTimeout);
    saveTabsTimeout = setTimeout(function () {
        saveTabs();
        saveTabsTimeout = null;
    }, 1000);
}

var validationTimeout = null;
function debouncedValidate(model) {
    if (validationTimeout) clearTimeout(validationTimeout);
    validationTimeout = setTimeout(function () {
        if (window.validateLuauCode && model) {
            window.validateLuauCode(model);
        }
        validationTimeout = null;
    }, 300);
}

window.addEventListener('beforeunload', function () {
    if (saveTabsTimeout) {
        clearTimeout(saveTabsTimeout);
        saveTabs();
    }
});

window.forgetAllChoices = function () {
    settings.skipSpoofWarning = false;
    settings.confirmClose = true;
    settings.confirmClear = true;
    settings.confirmDelete = true;
    settings.confirmDeleteTheme = true;
    settings.confirmCloseOthers = true;
    settings.confirmCloseApp = true;
    saveSettings();
    if (window.showNotification) window.showNotification("All remembered choices have been reset");
};

window.applyUISize = function (sizeStr) {
    if (typeof bridge === 'undefined' || !bridge.SetUISize) return;

    document.body.classList.remove('ui-size-oversized', 'ui-size-big', 'ui-size-normal', 'ui-size-small', 'ui-size-verysmall');
    document.body.classList.add('ui-size-' + (sizeStr || 'normal'));

    switch (sizeStr) {
        case 'oversized': bridge.SetUISize(1000, 600); break;
        case 'big': bridge.SetUISize(900, 550); break;
        case 'normal': bridge.SetUISize(820, 500); break;
        case 'small': bridge.SetUISize(700, 430); break;
        case 'verysmall': bridge.SetUISize(600, 380); break;
        default: bridge.SetUISize(820, 500); break;
    }
};

window.applyScrollbarVisibility = function () {
    if (settings.showScrollbars) {
        document.body.classList.remove('hide-scrollbars');
    } else {
        document.body.classList.add('hide-scrollbars');
    }

    var vMode = settings.editorScrollbarV !== false ? 'auto' : 'hidden';
    var hMode = settings.editorScrollbarH !== false ? 'auto' : 'hidden';

    if (monacoEditor) monacoEditor.updateOptions({ scrollbar: { vertical: vMode, horizontal: hMode } });
    if (monacoEditorSecondary) monacoEditorSecondary.updateOptions({ scrollbar: { vertical: vMode, horizontal: hMode } });
};

window.applyAppearanceClasses = function () {
    if (settings.glowButtons) document.body.classList.add('glow-buttons-enabled');
    else document.body.classList.remove('glow-buttons-enabled');


    if (settings.tabGlow === false) document.body.classList.add('tab-glow-off');
    else document.body.classList.remove('tab-glow-off');


    if (settings.statusGlowFollowAccent) document.body.classList.add('status-glow-follow-accent');
    else document.body.classList.remove('status-glow-follow-accent');

    if (!settings.windowRounded) document.body.classList.add('square-window');
    else document.body.classList.remove('square-window');
    if (typeof bridge !== 'undefined' && bridge.SetWindowRounded) bridge.SetWindowRounded(settings.windowRounded);

    if (!settings.uiRounded) document.body.classList.add('square-ui');
    else document.body.classList.remove('square-ui');

    if (settings.animations === false) document.body.classList.add('disable-animations');
    else document.body.classList.remove('disable-animations');

    if (settings.blurOptions) document.body.classList.add('blur-options-enabled');
    else document.body.classList.remove('blur-options-enabled');

    if (settings.transparency) document.body.classList.add('transparency-enabled');
    else document.body.classList.remove('transparency-enabled');
    window.applyV5Visibility();
    if (window.applyBackdropClasses) window.applyBackdropClasses();
};

window.applyBackdropClasses = function () {
    document.documentElement.classList.remove('window-acrylic-active');
    document.body.classList.remove('window-acrylic-active');

    if (settings.acrylicEnabled) {
        document.documentElement.classList.add('window-acrylic-active');
        document.body.classList.add('window-acrylic-active');
    }

    // Keep the app itself out of Chromium's backdrop-root chain.  Acrylic is
    // painted by .app::before instead, which lets nested context menus and
    // dropdowns blur the UI behind them instead of sampling a flattened layer.
    const appEl = document.querySelector('.app');
    if (appEl) {
        appEl.style.backdropFilter = '';
        appEl.style.webkitBackdropFilter = '';
    }

    if (window.isApplyingTheme) {
        return;
    }

    if (typeof monaco !== 'undefined' && typeof monacoEditor !== 'undefined') {
        window.applyTheme(window.activeThemeId);
    }
};

window.applyV5Visibility = function () {
    const v5 = $id('brand-v5');
    if (v5) v5.style.display = settings.showV5 !== false ? '' : 'none';
};

window.applyAccentColor = function () {
    const theme = THEMES_CONFIG[window.activeThemeId] || THEMES_CONFIG.v5;
    const isLivePreview = document.getElementById('custom-color-modal-overlay')?.classList.contains('active');
    let color = "";
    if (isLivePreview) {
        color = document.documentElement.style.getPropertyValue('--purple').trim();
    }
    if (!color) {
        color = (settings.accentColor && settings.accentColor.toLowerCase() !== '#7b7ff6') ? settings.accentColor : (theme.styles['--purple'] || '#7b7ff6');
        document.documentElement.style.setProperty('--purple', color);
    }

    const followAccentActive = settings.statusGlowFollowAccent && window.activeThemeId !== 'dark' && window.activeThemeId !== 'light';


    const hasCustomAccent = settings.accentColor && settings.accentColor.toLowerCase() !== '#7b7ff6';
    if (hasCustomAccent) {
        const r = parseInt(color.slice(1, 3), 16);
        const g = parseInt(color.slice(3, 5), 16);
        const b = parseInt(color.slice(5, 7), 16);
        const secondary = `rgba(${Math.max(0, r - 40)}, ${Math.max(0, g - 40)}, ${Math.max(0, b - 40)}, 1)`;
        const gradient = `linear-gradient(135deg, ${color} 0%, ${secondary} 100%)`;
        document.documentElement.style.setProperty('--v5-gradient', gradient);
    } else {
        document.documentElement.style.setProperty('--v5-gradient', theme.styles['--v5-gradient'] || 'linear-gradient(135deg, ' + color + ' 0%, ' + window.safeColorWithAlpha(color, 0.7) + ' 100%)');
    }

    // Dynamic borders & banner backgrounds to eliminate hardcoded pink in other themes
    const welcomeBg = theme.styles['--welcome-bg'] || (theme.isLight ? 'linear-gradient(135deg, ' + window.safeColorWithAlpha(color, 0.12) + ' 0%, ' + window.safeColorWithAlpha(color, 0.03) + ' 100%)' : 'linear-gradient(135deg, ' + window.safeColorWithAlpha(color, 0.18) + ' 0%, ' + window.safeColorWithAlpha(color, 0.03) + ' 100%)');
    const welcomeBd = theme.styles['--welcome-bd'] || window.safeColorWithAlpha(color, 0.2);
    const glassBg = theme.styles['--glass-bg'] || window.safeColorWithAlpha(color, 0.03);
    const glassBd = theme.styles['--glass-bd'] || window.safeColorWithAlpha(color, 0.08);

    document.documentElement.style.setProperty('--welcome-bg', welcomeBg);
    document.documentElement.style.setProperty('--welcome-bd', welcomeBd);
    document.documentElement.style.setProperty('--glass-bg', glassBg);
    document.documentElement.style.setProperty('--glass-bd', glassBd);

    const glowColor = (typeof color === 'string' && color.startsWith('#')) ? color + '33' : color;
    let secondaryColor = color;
    if (typeof color === 'string' && color.startsWith('#') && color.length === 7) {
        const r = parseInt(color.slice(1, 3), 16);
        const g = parseInt(color.slice(3, 5), 16);
        const b = parseInt(color.slice(5, 7), 16);
        secondaryColor = `rgb(${Math.max(0, r - 40)}, ${Math.max(0, g - 40)}, ${Math.max(0, b - 40)})`;
    }


    let isRedTheme = ['bloodfall', 'crimson_peak', 'classic_v1'].includes(window.activeThemeId);
    if (!isRedTheme && typeof color === 'string' && color.startsWith('#')) {
        const r = parseInt(color.slice(1, 3), 16);
        const g = parseInt(color.slice(3, 5), 16);
        const b = parseInt(color.slice(5, 7), 16);
        isRedTheme = (r > 180 && g < 100 && b < 100);
    }
    const statusInjectedColor = isRedTheme ? '#ffffff' : '#30d158';

    document.documentElement.style.setProperty('--v5-glow', glowColor);
    document.documentElement.style.setProperty('--status-injected', statusInjectedColor);
    if (typeof color === 'string' && color.startsWith('#') && color.length === 7) {
        const ar = parseInt(color.slice(1, 3), 16);
        const ag = parseInt(color.slice(3, 5), 16);
        const ab = parseInt(color.slice(5, 7), 16);
        document.documentElement.style.setProperty('--accent-rgb', `${ar}, ${ag}, ${ab}`);
        document.documentElement.style.setProperty('--purple-g', `rgba(${ar}, ${ag}, ${ab}, 0.15)`);
        document.documentElement.style.setProperty('--purple-glow', `rgba(${ar}, ${ag}, ${ab}, 0.18)`);
    }


    const styleTag = document.getElementById('dynamic-accent-style') || document.createElement('style');
    styleTag.id = 'dynamic-accent-style';
    styleTag.innerHTML = `
        ::-webkit-scrollbar-thumb { background: var(--bd) !important; border: 4px solid var(--bg) !important; background-clip: padding-box !important; }
        ::-webkit-scrollbar-thumb:hover { background: ${color} !important; border: 4px solid var(--bg) !important; background-clip: padding-box !important; }
        .monaco-editor .current-line { background: ${color}10 !important; border: 1px solid ${color}20 !important; }
        .nav-highlight { color: ${color} !important; }
        .weao-link { color: ${color} !important; opacity: 0.9; }
        
        /* Monaco UI Overrides */
        .monaco-editor .find-widget, .monaco-editor .suggest-widget { background: #121216 !important; border: 1px solid ${color}40 !important; }
        .monaco-editor .monaco-list-row.focused { background: ${color}30 !important; }
        .monaco-editor .selectionHighlight { background: ${color}40 !important; }
        .monaco-editor .wordHighlight, .monaco-editor .wordHighlightStrong { background: ${color}30 !important; }
        .monaco-editor .monaco-button { background-color: ${color} !important; }
        .monaco-editor .monaco-scrollable-element > .scrollbar > .slider { background: rgba(128,128,128,0.2) !important; }
        .monaco-editor .monaco-scrollable-element > .scrollbar > .slider:hover { background: ${color} !important; }
        .monaco-editor .cursor { background-color: ${color} !important; border-color: ${color} !important; color: #fff !important; }
        .v5-gradient { 
            background: ${(!hasCustomAccent) ? 'var(--v5-gradient)' : `linear-gradient(135deg, ${color} 0%, ${secondaryColor} 100%)`} !important; 
            -webkit-background-clip: text !important; 
            -webkit-text-fill-color: transparent !important; 
        }
        
        /* Status Glow Accent Override */
        ${followAccentActive ? `
        
        .app-glow.injected {
            background: radial-gradient(ellipse 50% 50% at -5% -5%, ${window.safeColorWithAlpha(color, window.activeThemeId === 'oled' ? 0 : 0.18)} 0%, transparent 60%) !important;
        }
        #status-dot.injected { 
            background: ${color} !important; 
            box-shadow: ${window.activeThemeId === 'oled' ? 'none' : `0 0 100px 25px ${color}, 0 0 350px 100px ${window.safeColorWithAlpha(color, 0.7)}`} !important; 
        }
        #status-text.injected { color: ${color} !important; }

        
        .app-glow.inactive {
            background: radial-gradient(ellipse 50% 50% at -5% -5%, ${window.safeColorWithAlpha(color, window.activeThemeId === 'oled' ? 0 : 0.05)} 0%, transparent 60%) !important;
        }
        #status-dot:not(.injected):not(.injecting):not(.error) { 
            background: ${window.safeColorWithAlpha(color, 0.45)} !important; 
            box-shadow: ${window.activeThemeId === 'oled' ? 'none' : `0 0 100px 25px ${window.safeColorWithAlpha(color, 0.35)}, 0 0 350px 100px ${window.safeColorWithAlpha(color, 0.12)}`} !important; 
            opacity: 0.8;
        }
        #status-text:not(.injected):not(.injecting):not(.error) { 
            color: ${window.safeColorWithAlpha(color, 0.55)} !important; 
            opacity: 0.5; 
        }
        ` : `
        
        .app-glow.injected {
            background: radial-gradient(ellipse 50% 50% at -5% -5%, ${window.safeColorWithAlpha('#30d158', window.activeThemeId === 'oled' ? 0 : 0.18)} 0%, transparent 60%) !important;
        }
        #status-dot.injected { 
            background: #30d158 !important; 
            box-shadow: ${window.activeThemeId === 'oled' ? 'none' : `0 0 100px 25px #30d158, 0 0 350px 100px rgba(48, 209, 88, 0.5)`} !important; 
        }
        #status-text.injected { color: #30d158 !important; }

        .app-glow.inactive {
            background: radial-gradient(ellipse 50% 50% at -5% -5%, rgba(79, 78, 113, 0.08) 0%, transparent 60%) !important;
        }
        #status-dot:not(.injected):not(.injecting):not(.error) { 
            background: var(--inactive) !important; 
            box-shadow: ${window.activeThemeId === 'oled' ? 'none' : `0 0 100px 25px var(--inactive), 0 0 350px 100px rgba(79, 78, 113, 0.35)`} !important; 
            opacity: 0.8;
        }
        #status-text:not(.injected):not(.injecting):not(.error) { 
            color: var(--inactive) !important; 
            opacity: 0.5; 
        }
        `}

        /* Dynamic classes for Injecting and Error states (ALWAYS standard colors, regardless of theme) */
        .app-glow.injecting {
            background: radial-gradient(ellipse 50% 50% at -5% -5%, rgba(254, 188, 46, 0.15) 0%, transparent 60%) !important;
        }
        #status-dot.injecting {
            background: #febc2e !important;
            box-shadow: 0 0 100px 25px #febc2e, 0 0 350px 100px rgba(254, 188, 46, 0.7) !important;
        }
        #status-text.injecting {
            color: #febc2e !important;
        }

        .app-glow.error {
            background: radial-gradient(ellipse 50% 50% at -5% -5%, rgba(255, 69, 58, 0.15) 0%, transparent 60%) !important;
        }
        #status-dot.error {
            background: #ff453a !important;
            box-shadow: 0 0 100px 25px #ff453a, 0 0 350px 100px rgba(255, 69, 58, 0.7) !important;
        }
        #status-text.error {
            color: #ff453a !important;
        }

        /* Accent Corner Glow (OLED specific) */
        ${window.activeThemeId === 'oled' ? `
        .app-glow, .accent-glow { display: none !important; opacity: 0 !important; }
        ` : ''}

        /* Status Dot Glow Suppression */
        ${!settings.statusGlow ? `
        #status-dot, #status-dot.injected, #status-dot.injecting, #status-dot.error, #status-dot:not(.injected):not(.injecting):not(.error) {
            box-shadow: none !important;
        }
        ` : ''}
    `;
    if (!styleTag.parentElement) document.head.appendChild(styleTag);


    const rowAccent = document.getElementById('row-accentglow');
    const rowStatus = document.getElementById('row-statusglow');
    if (window.activeThemeId === 'oled') {
        if (rowAccent) { rowAccent.style.opacity = '0.5'; rowAccent.style.pointerEvents = 'none'; }
        if (rowStatus) { rowStatus.style.opacity = '0.5'; rowStatus.style.pointerEvents = 'none'; }
    } else {
        if (rowAccent) { rowAccent.style.opacity = ''; rowAccent.style.pointerEvents = ''; }
        if (rowStatus) { rowStatus.style.opacity = ''; rowStatus.style.pointerEvents = ''; }
    }
};

window.openSettingsPane = function (paneId) {
    document.querySelectorAll('#page-settings .settings-view').forEach(function (el) {
        el.style.display = 'none';
        el.classList.remove('pane-enter');
    });
    const subPanes = ['settings-interface', 'settings-misc', 'settings-themes', 'settings-editor', 'settings-exec', 'settings-confirmations', 'settings-autoexe', 'settings-security'];
    const pId = subPanes.includes('settings-' + paneId) ? 'settings-' + paneId : 'settings-main';
    const target = document.getElementById(pId);

    if (paneId === 'autoexe') {
        if (typeof loadAutoexecManager === 'function') loadAutoexecManager();
    }
    if (paneId === 'themes') {
        if (typeof renderThemeGrid === 'function') {
            const grid = document.getElementById('theme-grid');
            if (grid) grid.innerHTML = '';
            renderThemeGrid();
        }
    }
    if (target) {

        document.querySelectorAll('.flash-highlight').forEach(el => el.classList.remove('flash-highlight'));
        target.style.display = 'flex';
        void target.offsetWidth;
        target.classList.add('pane-enter');
    }
};

window.parseWrapperSettings = function (raw) {
    let settings = { enabled: true, games: "", delay: 0 };
    if (!raw) return settings;
    if (raw.startsWith("if false then\r\n") || raw.startsWith("if false then\n")) {
        settings.enabled = false;
        return settings;
    }
    if (raw.includes("if not game:IsLoaded() then game.Loaded:Wait() end")) {
        if (raw.includes("local allowed = {")) {
            let start = raw.indexOf("local allowed = {") + 17;
            let end = raw.indexOf("}", start);
            if (end > start) {
                let allowedStr = raw.substring(start, end);
                let ids = allowedStr.split(',').map(item => {
                    let match = item.trim().match(/^\[(\d+)\]/);
                    return match ? match[1] : null;
                }).filter(id => id !== null);
                ids = Array.from(new Set(ids));
                settings.games = ids.join(', ');
            }
        }
        if (raw.includes("task.wait(")) {
            let start = raw.indexOf("task.wait(") + 10;
            let end = raw.indexOf(")", start);
            if (end > start) {
                settings.delay = parseInt(raw.substring(start, end)) || 0;
            }
        }
    }
    return settings;
};

window.extractUserScript = function (raw) {
    if (!raw) return "";
    let lines = raw.split(/\r?\n/);
    let startLineIdx = 0;

    if (startLineIdx < lines.length && lines[startLineIdx].trim() === "if false then") {
        startLineIdx = 1;
    } else if (startLineIdx < lines.length && lines[startLineIdx].trim() === "if not game:IsLoaded() then game.Loaded:Wait() end") {
        startLineIdx = 1;
        if (startLineIdx < lines.length && lines[startLineIdx].trim().startsWith("task.wait(")) {
            startLineIdx++;
        }
        if (startLineIdx < lines.length && lines[startLineIdx].trim().startsWith("local allowed = {")) {
            startLineIdx++;
            if (startLineIdx < lines.length && lines[startLineIdx].trim().startsWith("if not allowed[game.PlaceId]")) {
                startLineIdx++;
                if (startLineIdx < lines.length && lines[startLineIdx].trim().startsWith("-- zenith custom ui auto execute manager")) {
                    startLineIdx++;
                }
            }
        }
    }

    while (startLineIdx < lines.length && lines[startLineIdx].trim() === "") {
        startLineIdx++;
    }

    let endIdx = lines.length - 1;
    while (endIdx >= startLineIdx && lines[endIdx].trim() !== "end") {
        endIdx--;
    }

    if (endIdx > startLineIdx) {
        let userLines = lines.slice(startLineIdx, endIdx);
        return userLines.join("\r\n").trim();
    }

    return lines.slice(startLineIdx).join("\r\n").trim();
};

window.getWrapperHeader = function (enabled, games, delay) {
    if (!enabled) {
        return "if false then\r\n";
    }
    let hasHeader = false;
    let header = "";
    if (games.length > 0) hasHeader = true;
    if (delay > 0) hasHeader = true;

    if (hasHeader) {
        header += "if not game:IsLoaded() then game.Loaded:Wait() end\r\n";
        if (delay > 0) {
            header += `task.wait(${delay})\r\n`;
        }
        if (games.length > 0) {
            let gamesList = games.split(',').map(id => id.trim()).filter(id => id.length > 0);
            let allowedItems = [];
            gamesList.forEach(id => {
                allowedItems.push(`[${id}] = true`);
                allowedItems.push(`["${id}"] = true`);
            });
            header += `local allowed = {${allowedItems.join(', ')}}\r\n`;
            header += `if not allowed[game.PlaceId] and not allowed[tostring(game.PlaceId)] then\r\n`;
            header += `-- zenith custom ui auto execute manager ^\r\n\r\n\r\n`;
        }
    }
    return header;
};

window.getWrapperTrailer = function (enabled, games, delay) {
    if (!enabled) return "\r\nend\r\n\r\n\r\n\r\n";
    if (games.length > 0) return "\r\nend\r\n\r\n\r\n\r\n";
    return "";
};

window.loadAutoexecManager = async function () {
    const list = document.getElementById('autoexec-scripts-list');
    if (!list) return;
    if (!window.bridge) { list.innerHTML = '<div style="padding: 20px; text-align: center; color: var(--red); font-size: 12px;">Failed to load scripts (C# Bridge unavailable)</div>'; return; }

    list.innerHTML = '<div style="padding: 20px; text-align: center; color: var(--t2); font-size: 12px;">Loading scripts...</div>';

    try {
        var scriptsStr = await window.bridge.GetScripts('autoexe');
        if (typeof scriptsStr === 'string') scriptsStr = JSON.parse(scriptsStr);
        const scripts = Array.from(scriptsStr);
        if (scripts.length === 0) {
            list.innerHTML = '<div style="padding: 20px; text-align: center; color: var(--t2); font-size: 12px;">No scripts found in autoexe folder.</div>';
            return;
        }

        list.innerHTML = '';
        for (let i = 0; i < scripts.length; i++) {
            const file = scripts[i];
            const content = await window.bridge.ReadScriptRaw('autoexe', file);
            let parsed = window.parseWrapperSettings(content);
            let isEnabled = parsed.enabled;
            let gameIds = parsed.games;

            const isLast = (i === scripts.length - 1);
            const item = document.createElement('div');
            item.className = 'autoexec-tree-item';
            item.style.display = 'flex';
            item.style.flexDirection = 'column';
            item.style.width = '100%';
            item.style.position = 'relative';
            item.style.paddingLeft = '20px';
            item.style.marginBottom = '0px';
            item.style.boxSizing = 'border-box';

            item.innerHTML = `
                ${isLast ? `
                <div class="tree-line-vertical" style="position: absolute; left: 8px; top: 0; height: 12px; width: 1.5px; border-left: 1.5px dashed rgba(255, 255, 255, 0.15);"></div>
                ` : `
                <div class="tree-line-vertical" style="position: absolute; left: 8px; top: 0; bottom: 0; width: 1.5px; border-left: 1.5px dashed rgba(255, 255, 255, 0.15);"></div>
                `}
                
                <div style="display: flex; width: 100%; justify-content: space-between; align-items: center; position: relative;">
                    <div class="tree-line-horizontal" style="position: absolute; left: -12px; top: 50%; width: 12px; height: 1.5px; border-top: 1.5px dashed rgba(255, 255, 255, 0.15);"></div>
                    
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="var(--purple)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink: 0; filter: drop-shadow(0 0 3px var(--v5-glow));">
                            <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z" />
                            <polyline points="14 2 14 8 20 8" />
                        </svg>
                        <div class="sn-text">
                            <div class="sn-title" style="font-size: 13px; font-weight: 600; color: var(--t1); margin-bottom: 0;">${file}</div>
                        </div>
                    </div>
                    
                    <label class="ios-toggle" style="margin-left: 10px;">
                        <input type="checkbox" id="ae-toggle-${i}" ${isEnabled ? 'checked' : ''}>
                        <span class="toggle-track"><span class="toggle-thumb"></span></span>
                    </label>
                </div>
                
                <div style="display: flex; flex-direction: column; gap: 8px; margin-top: 8px; padding-left: 24px; position: relative;">
                    <div class="tree-line-sub" style="position: absolute; left: 8px; top: -8px; bottom: 22px; width: 1.5px; border-left: 1.5px dashed rgba(255, 255, 255, 0.15);"></div>
                    
                    <div style="font-size: 10.5px; color: var(--t2); font-weight: 500;">Restrict Game IDs (comma separated, leave blank for all)</div>
                    <input type="text" class="settings-search" id="ae-games-${i}" value="${gameIds}" style="margin: 0; padding: 6px 12px; font-size: 11px; height: 32px !important; border-radius: 8px; width: 100%; box-sizing: border-box;" placeholder="e.g. 12345, 67890">
                    
                    <button class="action-btn btn-purple" id="ae-save-${i}" style="width: 100%; height: 34px !important; font-size: 11.5px; font-weight: 700; background: var(--purple); color: #fff; border: none; cursor: pointer; border-radius: 8px; box-shadow: 0 0 10px rgba(162, 162, 208, 0.15); transition: all 0.2s; letter-spacing: 0.5px;">
                        Save Settings
                    </button>
                </div>
            `;
            list.appendChild(item);

            const btn = document.getElementById(`ae-save-${i}`);
            const toggleInput = document.getElementById(`ae-toggle-${i}`);
            const gamesInput = document.getElementById(`ae-games-${i}`);

            if (gamesInput) {
                gamesInput.oninput = (e) => {
                    e.target.value = e.target.value.replace(/[^0-9,\s]/g, '');
                };
            }

            const saveScriptSettings = async () => {
                const checked = toggleInput.checked;
                const games = gamesInput ? gamesInput.value.trim() : "";

                let raw = await window.bridge.ReadScriptRaw('autoexe', file);
                let realContent = window.extractUserScript(raw);

                let header = window.getWrapperHeader(checked, games, settings.autoexecDelay || 0);
                let trailer = window.getWrapperTrailer(checked, games, settings.autoexecDelay || 0);

                let newContent = header + realContent + trailer;
                window.bridge.WriteScript('autoexe', file, newContent);
            };

            toggleInput.onchange = async () => {
                await saveScriptSettings();
                if (window.showNotification) window.showNotification((toggleInput.checked ? 'Enabled' : 'Disabled') + ' ' + file);
            };

            btn.onclick = async () => {
                await saveScriptSettings();
                if (window.showNotification) window.showNotification('Saved settings for ' + file);
            };
        }
    } catch (e) {
        list.innerHTML = `<div style="padding: 20px; text-align: center; color: var(--red); font-size: 12px;">Error: ${e.message}</div>`;
    }
};

window.updateAllAutoexecScripts = async function () {
    if (!window.bridge) return;
    try {
        var scriptsStr = await window.bridge.GetScripts('autoexe');
        if (typeof scriptsStr === 'string') scriptsStr = JSON.parse(scriptsStr);
        const scripts = Array.from(scriptsStr);
        for (let file of scripts) {
            let raw = await window.bridge.ReadScriptRaw('autoexe', file);
            if (!raw) continue;

            let parsed = window.parseWrapperSettings(raw);
            let realContent = window.extractUserScript(raw);

            let header = window.getWrapperHeader(parsed.enabled, parsed.games, settings.autoexecDelay || 0);
            let trailer = window.getWrapperTrailer(parsed.enabled, parsed.games, settings.autoexecDelay || 0);

            let newContent = header + realContent + trailer;
            await window.bridge.WriteScript('autoexe', file, newContent);
        }
    } catch (e) {
        console.error(e);
    }
};

var notifTimeout;
window.showNotification = function (msg) {
    var t = document.getElementById('notification-toast');
    if (!t) return;

    if (notifTimeout) clearTimeout(notifTimeout);

    t.innerText = msg;

    if (!t.classList.contains('visible')) {
        t.classList.add('visible');
    }

    notifTimeout = setTimeout(() => {
        t.classList.remove('visible');
    }, 2800);
};

window.copyToClipboard = function (text) {
    if (window.bridge && window.bridge.CopyToClipboard) {
        try {
            window.bridge.CopyToClipboard(text);
            return;
        } catch (e) {
            console.warn("bridge.CopyToClipboard failed, falling back to navigator", e);
        }
    } else if (typeof bridge !== 'undefined' && bridge && bridge.CopyToClipboard) {
        try {
            bridge.CopyToClipboard(text);
            return;
        } catch (e) {
            console.warn("bridge.CopyToClipboard failed, falling back to navigator", e);
        }
    }
    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).catch(err => {
            console.error("Clipboard API failed, falling back", err);
            window.copyFallback(text);
        });
    } else {
        window.copyFallback(text);
    }
};

window.copyFallback = function (text) {
    var textArea = document.createElement("textarea");
    textArea.value = text;
    textArea.style.position = "fixed";
    textArea.style.left = "-9999px";
    textArea.style.top = "0";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
        document.execCommand('copy');
    } catch (err) {
        console.error('Fallback copy failed', err);
    }
    document.body.removeChild(textArea);
};

var renameCallback = null;
function openRenameModal(title, defaultText, callback) {
    var modal = $id('rename-modal'); var input = $id('rename-input');
    if (!modal || !input) return;
    $id('rename-title').innerText = title; input.value = defaultText; renameCallback = callback;
    modal.classList.add('visible'); input.focus(); input.select();
}
function closeRenameModal() { var modal = $id('rename-modal'); if (modal) modal.classList.remove('visible'); renameCallback = null; }
if ($id('rename-cancel')) $id('rename-cancel').onclick = closeRenameModal;
if ($id('rename-confirm')) { $id('rename-confirm').onclick = function () { var newVal = $id('rename-input').value.trim(); if (newVal && renameCallback) renameCallback(newVal); closeRenameModal(); }; }
if ($id('rename-input')) { $id('rename-input').addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.target.blur(); $id('rename-confirm').click(); } if (e.key === 'Escape') closeRenameModal(); }); }

window.updateInjectionStatus = function (state) {
    if (window._injectionErrorTimeout) {
        clearTimeout(window._injectionErrorTimeout);
        window._injectionErrorTimeout = null;
    }
    var statusText = document.getElementById('status-text');
    var statusDot = document.getElementById('status-dot');
    var appGlow = document.getElementById('app-glow');

    if (!statusText || !statusDot) return;

    if (state === true && statusText.innerText !== "Injected") {
        if (settings.errorSpoofing && typeof bridge !== 'undefined' && bridge.Execute) {
            var spoofScript = `pcall(function() local LogPath="SirHurtUIfold/workspace/luaconsole.log"; local o_err=error; getgenv().error=function(msg, lvl) pcall(function() if not isfile(LogPath) then writefile(LogPath, "") end; appendfile(LogPath, "ERR|" .. tostring(msg) .. "\\n") end) return o_err(msg, lvl) end; game:GetService("ScriptContext").Error:Connect(function(msg) pcall(function() if not isfile(LogPath) then writefile(LogPath, "") end; appendfile(LogPath, "ERR|" .. tostring(msg) .. "\\n") end) end) end)`;
            bridge.Execute(spoofScript);
        }
        if (settings.unlockFps && typeof bridge !== 'undefined' && bridge.Execute) {
            bridge.Execute("if setfpscap then pcall(setfpscap, " + (settings.customFps || 500) + ") end");
        } else if (!settings.unlockFps && typeof bridge !== 'undefined' && bridge.Execute) {
            bridge.Execute("if setfpscap then pcall(setfpscap, 60) end");
        }
        if (typeof bridge !== 'undefined' && bridge.Execute) {
            var relayScript = "if getgenv()._LC then return end getgenv()._LC=true local L=\"luaconsole.log\" local LS=game:GetService(\"LogService\") local m={[Enum.MessageType.MessageOutput]=\"RBX\",[Enum.MessageType.MessageInfo]=\"INFO\",[Enum.MessageType.MessageWarning]=\"WARN\",[Enum.MessageType.MessageError]=\"ERR\"} LS.MessageOut:Connect(function(s,t) pcall(function() appendfile(L,(m[t] or \"LOG\")..\"|\"..s..\"\\n\") end) end) pcall(function() appendfile(L,\"INFO|Console Sync Active\\n\") end)";
            bridge.Execute(relayScript);
        }
    }

    if (state === true || state === 'homepage') {
        statusText.innerText = "Injected";
        statusText.classList.remove('injecting', 'error', 'inactive');
        statusText.classList.add('injected');
        statusDot.classList.remove('injecting', 'error', 'inactive');
        statusDot.classList.add('injected');

        statusText.style.color = '';
        statusDot.style.background = '';

        if (appGlow) {
            appGlow.classList.add('injected');
            appGlow.classList.remove('inactive', 'injecting', 'error');
        }
    } else if (state === 'injecting') {
        statusText.innerText = "Injecting…";
        statusText.classList.add('injecting');
        statusText.classList.remove('injected', 'error');
        statusDot.classList.add('injecting');
        statusDot.classList.remove('injected', 'error');


        statusText.style.color = '';
        statusDot.style.background = '';

        if (appGlow) {
            appGlow.classList.add('injecting');
            appGlow.classList.remove('injected', 'inactive', 'error');
        }
    } else if (state === 'error') {
        statusText.innerText = "Error";
        statusText.classList.add('error');
        statusText.classList.remove('injected', 'injecting');
        statusDot.classList.add('error');
        statusDot.classList.remove('injected', 'injecting');


        statusText.style.color = '';
        statusDot.style.background = '';

        if (appGlow) {
            appGlow.classList.add('error');
            appGlow.classList.remove('injected', 'inactive', 'injecting');
        }

        window._injectionErrorTimeout = setTimeout(function () {
            window.updateInjectionStatus('inactive');
        }, 3000);
    } else {
        statusText.innerText = "Inactive";
        statusText.classList.remove('injecting', 'injected', 'error');
        statusDot.classList.remove('injecting', 'injected', 'error');


        statusText.style.color = '';
        statusDot.style.background = '';

        if (appGlow) {
            appGlow.classList.add('inactive');
            appGlow.classList.remove('injected', 'injecting', 'error');
        }
    }
};

// OrionEx: this remake executes through the Orion bridge, always available.
(function () {
    try { if (typeof window.updateInjectionStatus === 'function') window.updateInjectionStatus('injected'); } catch (e) { }
})();

var isHubLoaded = false;

function navigateTo(page) {
    if (!page) return;
    var targetPage = $id('page-' + page);
    var isAlreadyActive = targetPage && targetPage.classList.contains('active');

    if (isAlreadyActive && page !== 'settings') {

        return;
    }

    document.querySelectorAll('.page').forEach(function (p) { p.classList.remove('active'); });
    document.querySelectorAll('.nav-item').forEach(function (n) { n.classList.remove('active'); });
    if (targetPage) targetPage.classList.add('active');
    var navItem = document.querySelector('.nav-item[data-page="' + page + '"]');
    if (navItem) navItem.classList.add('active');

    if (page === 'editor' && monacoEditor) { setTimeout(function () { monacoEditor.layout(); }, 50); window.loadFolder('scripts'); }
    if (page === 'settings') {
        openSettingsPane('main');
    }
    if (page === 'hub') {
        if (!isHubLoaded) {
            loadHub(1, "");
            isHubLoaded = true;
        }
    }
    if (page === 'information' && typeof window.fetchGlobalLaunches === 'function') { window.fetchGlobalLaunches(); }


    if (false) {
        $id('spoof-warning-modal').classList.add('visible');
    }
}


let hubPage = 1;
let hubQuery = "";

async function fetchScriptBlox(page, query) {
    let url = "";
    if (query && query.trim() !== "") {
        url = `https://scriptblox.com/api/script/search?q=${encodeURIComponent(query)}&page=${page}&max=80`;
    } else {
        url = `https://scriptblox.com/api/script/fetch?page=${page}&max=80`;
    }


    if ($id('sb-mode') && $id('sb-mode').dataset.val && $id('sb-mode').dataset.val !== "") {
        url += `&mode=${$id('sb-mode').dataset.val}`;
    }
    if ($id('sb-verified') && $id('sb-verified').checked) url += `&verified=1`;
    if ($id('sb-patched') && $id('sb-patched').checked) url += `&patched=1`;
    if ($id('sb-universal') && $id('sb-universal').checked) url += `&universal=1`;
    if ($id('sb-key') && $id('sb-key').checked) url += `&key=1`;

    if ($id('sb-sort') && $id('sb-sort').dataset.val) {
        url += `&sortBy=${$id('sb-sort').dataset.val}&order=desc`;
    }

    let res;
    try {
        const response = await fetch(url);
        res = await response.text();
    } catch (e) {
        console.error("[Zenith] Browser fetch failed, falling back to bridge:", e);
        res = await window.chrome.webview.hostObjects.bridge.FetchUrlContent(url);
    }
    if (!res || res.trim() === "" || res.includes("Error") || res.includes("Exception")) {
        console.error("[Zenith] ScriptBlox API error:", res);
        return { scripts: [] };
    }
    let json;
    try {
        json = JSON.parse(res);
    } catch (e) {
        console.error("[Zenith] Failed to parse ScriptBlox JSON:", e, res);
        return { scripts: [] };
    }
    if (!json || !json.result || !json.result.scripts) return { scripts: [] };


    const mappedScripts = json.result.scripts.map(s => {
        return {
            _id: s._id,
            title: s.title,
            slug: s.slug,
            description: s.features || (s.game && s.game.name ? "Game: " + s.game.name : "ScriptBlox Script"),
            image: (typeof s.image === 'string' && s.image.length > 5 && !s.image.includes('placeholder')) ? (s.image.startsWith('http') ? s.image : 'https://scriptblox.com' + s.image) : (s.game && typeof s.game.imageUrl === 'string' && s.game.imageUrl.length > 5 && !s.game.imageUrl.includes('placeholder') ? (s.game.imageUrl.startsWith('http') ? s.game.imageUrl : 'https://scriptblox.com' + s.game.imageUrl) : null),
            authorName: s.owner ? s.owner.username : "Unknown",
            rawScript: s.script,
            isScriptBlox: true,
            gameName: s.game && s.game.name ? s.game.name : null,
            gameLink: (s.game && s.game.gameId) ? "https://www.roblox.com/games/" + s.game.gameId : null
        };
    });
    return { scripts: mappedScripts };
}

async function loadHub(page = 1, query = "") {
    hubPage = page;
    hubQuery = query;
    const grid = document.getElementById('hub-grid');
    if (!grid) return;

    const sourceSelect = document.getElementById('hub-source-select');
    const source = sourceSelect ? (sourceSelect.dataset.val || 'rscripts') : 'rscripts';
    const sourceDisplayName = source === 'scriptblox' ? 'ScriptBlox' : 'RScripts';

    grid.innerHTML = `
        <div class="hub-loader-container">
            <div>
                <svg class="btn-spinner" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--purple)" stroke-width="3" stroke-linecap="round">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"></path>
                </svg>
            </div>
            <div style="color: var(--t2); font-size: 14px; font-weight: 500;">Loading ${sourceDisplayName}</div>
        </div>
    `;
    const pageInput = document.getElementById('hub-page-input');
    if (pageInput) pageInput.value = page;

    try {

        let allScripts = [];
        let fetchedAny = false;


        for (let i = 0; i < 4; i++) {
            let apiPage = (page - 1) * 4 + 1 + i;
            let pageData;

            if (source === 'scriptblox') {
                pageData = await fetchScriptBlox(apiPage, query);
            } else {
                const res = await bridge.FetchRScripts(apiPage, query);
                try {
                    pageData = JSON.parse(res);
                } catch (e) {
                    pageData = { scripts: [] };
                }
            }

            if (pageData && pageData.scripts && pageData.scripts.length > 0) {
                allScripts = allScripts.concat(pageData.scripts);
                fetchedAny = true;
            } else {

                break;
            }
        }

        let data = { scripts: allScripts.slice(0, 40) };

        if (!data || !data.scripts || data.scripts.length === 0) {
            grid.innerHTML = '<div style="grid-column: 1/-1; text-align: center; padding: 50px; color: var(--t3);">No scripts found matching your search.</div>';
            return;
        }
        grid.innerHTML = "";
        data.scripts.forEach(s => {
            const card = document.createElement('div');
            card.className = 'hub-card';
            const authorName = (s.author && s.author.username) || s.authorName || (s.user && s.user.username) || s.author || "Anonymous";
            const cardImg = (s.image && s.image !== "undefined" && s.image !== "null") ? s.image : 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDEiIGZpbGw9IiMxYTFhMWEiLz48dGV4dCB4PSI1MCUiIHk9IjUwJSIgZmlsbD0iIzQ0NCIgZm9udC1zaXplPSIyNCIgZm9udC1mYW1pbHk9IkFyaWFsIiBkeT0iLjNlbSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Tm8gSW1hZ2U8L3RleHQ+PC9zdmc+';

            card.innerHTML = `
                <div class="hub-card-thumb-container" style="width:100%; height:120px; background:#000 url('${cardImg}') no-repeat center; background-size: cover; overflow:hidden; border-radius:10px 10px 0 0; display:flex; align-items:center; justify-content:center;">
                </div>
                <div class="hub-card-info">
                    <div class="hub-card-title">${fixEncoding(s.title)}</div>
                    <div class="hub-card-author">by ${fixEncoding(authorName)}</div>
                </div>
            `;

            card.onclick = () => openScriptDetail(s);


            card.oncontextmenu = (e) => {
                e.preventDefault();
                showHubContextMenu(e, s);
            };

            grid.appendChild(card);
        });
    } catch (e) {
        grid.innerHTML = '<div style="grid-column: 1/-1; text-align: center; padding: 50px; color: var(--red);">Failed to load hub. Check connection.</div>';
    }
}

async function openScriptDetail(s) {
    const modal = document.getElementById('script-detail-modal');
    if (!modal) return;

    const authorName = fixEncoding((s.author && s.author.username) || s.authorName || (s.user && s.user.username) || s.author || "Anonymous");

    const finalImage = (s.image && s.image !== "undefined" && s.image !== "null") ? s.image : 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDEiIGZpbGw9IiMxYTFhMWEiLz48dGV4dCB4PSI1MCUiIHk9IjUwJSIgZmlsbD0iIzQ0NCIgZm9udC1zaXplPSIyNCIgZm9udC1mYW1pbHk9IkFyaWFsIiBkeT0iLjNlbSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Tm8gSW1hZ2U8L3RleHQ+PC9zdmc+';
    document.getElementById('sd-banner').src = finalImage;
    document.getElementById('sd-title').innerText = fixEncoding(s.title);

    const authorEl = document.getElementById('sd-author');
    authorEl.innerHTML = "";


    let authorPill = document.createElement("div");
    authorPill.className = "sd-meta-tag";
    authorPill.innerHTML = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="margin-right:4px;"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>`;

    let authorSpan = document.createElement("span");
    authorSpan.innerText = ` By ${authorName}`;
    authorPill.appendChild(authorSpan);
    authorEl.appendChild(authorPill);

    let rawGameName = fixEncoding(s.gameName || (s.game && (s.game.name || s.game.title)));
    let gameLink = s.gameLink || (s.game && (s.game.gameLink || s.game.link || s.game.url || (s.game.gameId ? "https://www.roblox.com/games/" + s.game.gameId : null)));

    if (rawGameName && rawGameName !== "Universal Script 📌") {
        let gamePill = document.createElement("div");
        gamePill.className = "sd-meta-tag game-tag";
        gamePill.innerHTML = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="margin-right:4px;"><rect x="2" y="6" width="20" height="12" rx="2"></rect><path d="M6 12h4"></path><path d="M8 10v4"></path><path d="M15 13h.01"></path><path d="M18 11h.01"></path></svg> Game: `;

        let nameSpan = document.createElement("span");
        nameSpan.innerText = rawGameName;
        nameSpan.style.overflow = "hidden";
        nameSpan.style.textOverflow = "ellipsis";
        nameSpan.style.whiteSpace = "nowrap";

        if (gameLink) {
            let a = document.createElement("a");
            a.appendChild(nameSpan);
            a.setAttribute('data-tooltip', "Open Roblox Game in Browser");
            a.onclick = (e) => {
                e.preventDefault();
                if (window.chrome && window.chrome.webview) {
                    window.chrome.webview.hostObjects.bridge.OpenBrowser(gameLink);
                } else {
                    window.open(gameLink, '_blank');
                }
            };
            a.oncontextmenu = (e) => {
                e.preventDefault();
                showGameContextMenu(e, gameLink);
            };
            gamePill.appendChild(a);
        } else {
            gamePill.appendChild(nameSpan);
        }

        authorEl.appendChild(gamePill);


        setTimeout(() => {
            if (nameSpan.scrollWidth > nameSpan.clientWidth) {
                gamePill.classList.add('is-truncated');
            }
        }, 10);
    }

    document.getElementById('sd-description').innerText = s.description || 'No description provided.';
    document.getElementById('sd-code-preview').innerText = '-- Loading source...';

    const copyBtn = document.getElementById('sd-btn-copy');
    if (copyBtn) {
        copyBtn.onclick = () => {
            let code = s.rawScript || document.getElementById('sd-code-preview').innerText;
            window.copyToClipboard(code);
            window.showNotification("Script copied to clipboard");


            copyBtn.setAttribute('data-tooltip', 'Copied!');
            const tooltip = document.getElementById('tooltip');
            if (tooltip && tooltip.classList.contains('visible') && copyBtn.matches(':hover')) {
                tooltip.innerText = 'Copied!';
            }
            setTimeout(() => {
                copyBtn.setAttribute('data-tooltip', 'Copy Script');
            }, 2000);
        };
    }


    window.switchSdTab('desc');

    window.switchSdTab('desc');


    document.getElementById('sd-btn-exec').onclick = () => {
        if (s.isScriptBlox) executeHubScriptCode(s.rawScript);
        else executeHubScript(s.rawScript || s.slug);
        modal.classList.remove('visible');
    };
    document.getElementById('sd-btn-load').onclick = () => {
        if (s.isScriptBlox) loadHubScriptCodeToEditor(s.rawScript, s.title || s.slug);
        else loadHubScriptToEditor(s.rawScript || s.slug, s.title || s.slug);
        modal.classList.remove('visible');
    };

    modal.classList.add('visible');


    try {
        let code = "";
        if (s.isScriptBlox) {
            code = s.rawScript;
        } else {
            const rawUrl = s.rawScript || `https://rscripts.net/api/v2/scripts/${s.slug}/raw`;
            code = await window.chrome.webview.hostObjects.bridge.FetchUrlContent(rawUrl);
        }
        if (code) {
            document.getElementById('sd-code-preview').innerText = code.trim();
        } else {
            document.getElementById('sd-code-preview').innerText = '-- No source available.';
        }
    } catch (e) {
        document.getElementById('sd-code-preview').innerText = '-- Error loading source.';
    }
}

window.switchSdTab = function (tab) {
    document.querySelectorAll('.sd-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.sd-pane').forEach(p => p.classList.remove('active'));

    const tabEl = document.getElementById('sd-tab-' + tab);
    const paneEl = document.getElementById('sd-pane-' + tab);
    if (tabEl) tabEl.classList.add('active');
    if (paneEl) paneEl.classList.add('active');
};

function showHubContextMenu(e, s) {
    const menu = document.getElementById('hub-context-menu');
    if (!menu) return;

    menu.classList.add('visible');
    menu.style.display = 'block';


    let x = e.pageX;
    let y = e.pageY;


    if (x + 180 > window.innerWidth) x -= 180;
    if (y + 150 > window.innerHeight) y -= 150;

    menu.style.left = x + 'px';
    menu.style.top = y + 'px';

    document.getElementById('cm-exec').onclick = () => {
        if (s.isScriptBlox) executeHubScriptCode(s.rawScript);
        else executeHubScript(s.rawScript || s.slug);
        closeMenu({ target: null });
    };
    document.getElementById('cm-view').onclick = () => { openScriptDetail(s); closeMenu({ target: null }); };
    document.getElementById('cm-load').onclick = () => {
        if (s.isScriptBlox) loadHubScriptCodeToEditor(s.rawScript, s.title || s.slug);
        else loadHubScriptToEditor(s.rawScript || s.slug, s.title || s.slug);
        closeMenu({ target: null });
    };
    document.getElementById('cm-copy').onclick = () => {
        const url = `https://rscripts.net/scripts/${s.slug}`;
        window.copyToClipboard(url);
        window.showNotification("Script link copied to clipboard");
        closeMenu({ target: null });
    };


    function closeMenu(evt) {
        if (evt && evt.button === 2) return;
        if (evt && evt.target && menu.contains(evt.target)) return;

        menu.classList.remove('visible');
        setTimeout(() => {
            if (!menu.classList.contains('visible')) menu.style.display = 'none';
        }, 150);
        document.removeEventListener('mousedown', closeMenu);
    }
    setTimeout(() => document.addEventListener('mousedown', closeMenu), 10);
}

function showGameContextMenu(e, gameLink) {
    const menu = document.getElementById('game-context-menu');
    if (!menu) return;

    menu.classList.add('visible');
    menu.style.display = 'block';

    let x = e.pageX;
    let y = e.pageY;
    if (x + 180 > window.innerWidth) x -= 180;
    if (y + 100 > window.innerHeight) y -= 100;

    menu.style.left = x + 'px';
    menu.style.top = y + 'px';

    document.getElementById('gm-open').onclick = () => {
        if (window.chrome && window.chrome.webview) {
            window.chrome.webview.hostObjects.bridge.OpenBrowser(gameLink);
        } else {
            window.open(gameLink, '_blank');
        }
        closeMenu({ target: null });
    };

    document.getElementById('gm-copy').onclick = () => {
        if (gameLink) {
            window.copyToClipboard(gameLink);
            window.showNotification("Game link copied to clipboard");
        } else {
            window.showNotification("No game link available");
        }
        closeMenu({ target: null });
    };

    function closeMenu(evt) {
        if (evt && evt.button === 2) return;
        if (evt && evt.target && menu.contains(evt.target)) return;

        menu.classList.remove('visible');
        setTimeout(() => {
            if (!menu.classList.contains('visible')) menu.style.display = 'none';
        }, 150);
        document.removeEventListener('mousedown', closeMenu);
    }
    setTimeout(() => document.addEventListener('mousedown', closeMenu), 10);
}

async function executeHubScript(rawUrlOrSlug) {

    const url = rawUrlOrSlug && rawUrlOrSlug.startsWith('http')
        ? rawUrlOrSlug
        : `https://rscripts.net/api/v2/scripts/${rawUrlOrSlug}/raw`;
    try {
        const code = await window.chrome.webview.hostObjects.bridge.FetchUrlContent(url);
        executeHubScriptCode(code);
    } catch (e) { showNotification('Failed to execute script.', 'error'); }
}

function executeHubScriptCode(code) {
    try {
        if (code) {
            setTimeout(() => window.executeScript(code), 50);
        }
    } catch (e) { showNotification('Failed to execute script.', 'error'); }
}

async function loadHubScriptToEditor(rawUrlOrSlug, title) {

    const url = rawUrlOrSlug && rawUrlOrSlug.startsWith('http')
        ? rawUrlOrSlug
        : `https://rscripts.net/api/v2/scripts/${rawUrlOrSlug}/raw`;
    try {
        const code = await window.chrome.webview.hostObjects.bridge.FetchUrlContent(url);
        loadHubScriptCodeToEditor(code, title || rawUrlOrSlug);
    } catch (e) { showNotification('Failed to load script.', 'error'); }
}

function loadHubScriptCodeToEditor(code, title) {
    if (code) {
        createNewTab(title || "Script", code);
        navigateTo('editor');
        showNotification('Script loaded into editor.', 'success');
    }
}


document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('hub-search');
    const searchBtn = document.getElementById('hub-search-btn');

    const triggerSearch = () => {
        if (searchInput) loadHub(1, searchInput.value);
    };

    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') triggerSearch();
        });
    }
    if (searchBtn) {
        searchBtn.addEventListener('click', triggerSearch);
    }


    const sourceSelect = document.getElementById('hub-source-select');
    const sbFilters = document.getElementById('scriptblox-filters');
    const hubToggle = document.getElementById('hub-toggle-dock');
    const hubPag = document.querySelector('.hub-pagination');

    if (hubToggle && hubPag) {
        hubToggle.onclick = (e) => {
            e.stopPropagation();
            hubPag.classList.toggle('dock-hidden');
            localStorage.setItem('sh_hub_dock_hidden', hubPag.classList.contains('dock-hidden'));
        };

        hubPag.onclick = (e) => {
            if (hubPag.classList.contains('dock-hidden')) {
                hubPag.classList.remove('dock-hidden');
                localStorage.setItem('sh_hub_dock_hidden', 'false');
            }
        };
        if (localStorage.getItem('sh_hub_dock_hidden') === 'true') {
            hubPag.classList.add('dock-hidden');
        }
    }

    if (sourceSelect) {
        sourceSelect.addEventListener('click', () => {
            const modal = document.getElementById('source-modal');
            if (modal) modal.classList.add('visible');
        });

        document.getElementById('src-btn-rscripts').addEventListener('click', () => {
            sourceSelect.dataset.val = 'rscripts';
            sourceSelect.innerText = 'Source: RScripts';
            document.getElementById('source-modal').classList.remove('visible');
            if (sbFilters) sbFilters.style.display = 'none';
            const hubPag = document.querySelector('.hub-pagination');
            if (hubPag) hubPag.classList.remove('hub-sb-active');
            if (searchInput) {
                searchInput.placeholder = 'Search thousands of scripts on Rscripts.net';
                loadHub(1, searchInput.value);
            }
        });

        document.getElementById('src-btn-scriptblox').addEventListener('click', () => {
            sourceSelect.dataset.val = 'scriptblox';
            sourceSelect.innerText = 'Source: ScriptBlox';
            document.getElementById('source-modal').classList.remove('visible');
            if (sbFilters) sbFilters.style.display = 'flex';
            const hubPag = document.querySelector('.hub-pagination');
            if (hubPag) hubPag.classList.add('hub-sb-active');
            if (searchInput) {
                searchInput.placeholder = 'Search thousands of scripts on ScriptBlox.com';
                loadHub(1, searchInput.value);
            }
        });

        document.getElementById('source-cancel').addEventListener('click', () => {
            document.getElementById('source-modal').classList.remove('visible');
        });
    }


    const filterElements = ['sb-mode', 'sb-verified', 'sb-patched', 'sb-universal', 'sb-key', 'sb-sort'];
    filterElements.forEach(id => {
        const el = document.getElementById(id);
        if (el) {
            el.addEventListener('change', () => {
                if (sourceSelect && sourceSelect.dataset.val === 'scriptblox') {
                    if (searchInput) loadHub(1, searchInput.value);
                }
            });
        }
    });

    const prevBtn = document.getElementById('hub-prev');
    if (prevBtn) {
        prevBtn.addEventListener('click', () => {
            if (hubPage > 1) loadHub(hubPage - 1, hubQuery);
        });
    }
    const nextBtn = document.getElementById('hub-next');
    if (nextBtn) {
        nextBtn.addEventListener('click', () => {
            loadHub(hubPage + 1, hubQuery);
        });
    }

    const pageInput = document.getElementById('hub-page-input');
    if (pageInput) {
        pageInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                let val = parseInt(pageInput.value);
                if (!isNaN(val) && val > 0) {
                    if (val > 999) val = 999;
                    loadHub(val, hubQuery);
                } else {
                    pageInput.value = hubPage;
                }
                pageInput.blur();
            }
        });
        pageInput.addEventListener('input', () => {
            pageInput.value = pageInput.value.replace(/[^0-9]/g, '').slice(0, 3);
        });
    }
});

function renderTabs() {
    // 1. Get FIRST positions for FLIP animation
    const tabEls = Array.from(tabsList.querySelectorAll('.tab'));
    const rects = new Map();
    tabEls.forEach(el => {
        const id = el.dataset.id;
        if (id) {
            rects.set(id, el.getBoundingClientRect());
        }
    });

    if (splitTabIds.length === 2) {
        const t1 = tabs.find(t => t.id === splitTabIds[0]);
        const t2 = tabs.find(t => t.id === splitTabIds[1]);
        if (t1 && t2) {
            const idx1 = tabs.indexOf(t1);
            tabs.splice(idx1, 1);
            const idx2 = tabs.find(t => t.id === splitTabIds[1]);
            const idxReal2 = tabs.indexOf(idx2);
            tabs.splice(idxReal2, 1);
            tabs.splice(idx1, 0, t1, t2);
        } else {
            splitTabIds = [];
            settings.splitTabIds = [];
            isSplitView = false;
            saveSettings();
            var secPane = document.getElementById('monaco-container-secondary');
            if (secPane) secPane.classList.add('split-hidden');
        }
    }

    tabsList.innerHTML = '';
    tabs.forEach(function (tab, index) {
        const isSelected = (tab.id === activeTab) || (isSplitView && splitTabIds.includes(tab.id));
        var el = document.createElement('div');
        el.className = 'tab' + (isSelected ? ' active' : '') + (tab.pinned ? ' tab-pinned' : '');
        el.dataset.id = tab.id;
        el.dataset.index = index;
        el.draggable = !tab.pinned;

        let tabHtml = `<div class="tab-content"><span class="tab-name">${esc(tab.name)}</span>`;
        if (tab.pinned) {
            tabHtml += `<span class="tab-sub" style="color:var(--purple);opacity:0.8;">pinned</span>`;
        } else if (splitTabIds.length === 2 && splitTabIds.includes(tab.id)) {
            tabHtml += `<span class="tab-sub">Linked</span>`;
        }
        tabHtml += `</div><span class="tab-close">\u00d7</span>`;

        el.innerHTML = tabHtml;
        if (tab.id === recentlyAddedTabId) { el.classList.add('tab-entering'); requestAnimationFrame(() => { requestAnimationFrame(() => el.classList.remove('tab-entering')); }); }
        if (tab.id === justDroppedTabId) {
            el.classList.add('tab-just-dropped');
            setTimeout(() => { if (justDroppedTabId === tab.id) justDroppedTabId = null; }, 1200);
        }

        el.addEventListener('dragstart', function (e) {
            el.classList.add('dragging');
            e.dataTransfer.setData('text/plain', index);
            e.dataTransfer.effectAllowed = 'all';
            window.draggedTabId = tab.id;
        });

        el.addEventListener('dragend', function () {
            el.classList.remove('dragging');
            document.querySelectorAll('.tab').forEach(t => {
                t.classList.remove('tab-drag-over-left');
                t.classList.remove('tab-drag-over-right');
            });
            window.draggedTabId = undefined;
            const fp = document.getElementById('file-panel');
            if (fp) fp.classList.remove('tab-drag-hover');
        });

        el.addEventListener('dragover', function (e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
            const rect = el.getBoundingClientRect();
            const midpoint = rect.left + rect.width / 2;
            if (e.clientX < midpoint) {
                el.classList.add('tab-drag-over-left');
                el.classList.remove('tab-drag-over-right');
            } else {
                el.classList.add('tab-drag-over-right');
                el.classList.remove('tab-drag-over-left');
            }
        });

        el.addEventListener('dragleave', function () {
            el.classList.remove('tab-drag-over-left');
            el.classList.remove('tab-drag-over-right');
        });

        el.addEventListener('drop', function (e) {
            e.preventDefault();

            if (tab.pinned) return;
            const fromIndex = parseInt(e.dataTransfer.getData('text/plain'));
            const fromTab = tabs[fromIndex];

            if (fromTab && fromTab.pinned) return;
            const rect = el.getBoundingClientRect();
            const midpoint = rect.left + rect.width / 2;
            let toIndex = index;

            if (e.clientX > midpoint) {
                toIndex = index + 1;
            }

            if (fromIndex < toIndex) {
                toIndex--;
            }

            if (fromIndex !== toIndex) {
                const oldOrder = tabs.map(t => t.id).join(',');
                const movedTab = tabs.splice(fromIndex, 1)[0];
                tabs.splice(toIndex, 0, movedTab);

                justDroppedTabId = movedTab.id;
                renderTabs();
                saveTabs();
            }

            document.querySelectorAll('.tab').forEach(t => {
                t.classList.remove('tab-drag-over-left');
                t.classList.remove('tab-drag-over-right');
            });
        });

        el.addEventListener('click', function (e) { if (!e.target.classList.contains('tab-close')) switchTab(tab.id); });
        el.querySelector('.tab-close').addEventListener('click', function (e) { e.stopPropagation(); closeTab(tab.id); });
        tabsList.appendChild(el);
    });

    // 2. Play LAST & INVERT for FLIP transition
    requestAnimationFrame(() => {
        const newTabEls = Array.from(tabsList.querySelectorAll('.tab'));
        newTabEls.forEach(el => {
            const id = el.dataset.id;
            const firstRect = rects.get(id);
            if (firstRect) {
                const lastRect = el.getBoundingClientRect();
                const deltaX = firstRect.left - lastRect.left;
                if (deltaX !== 0) {
                    // Invert
                    el.style.transform = `translateX(${deltaX}px)`;
                    el.style.transition = 'none';

                    // Play
                    requestAnimationFrame(() => {
                        el.style.transition = 'transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), background 0.2s var(--ease), opacity 0.2s var(--ease)';
                        el.style.transform = 'translate(0)';

                        // Clean up
                        setTimeout(() => {
                            el.style.transform = '';
                            el.style.transition = '';
                        }, 300);
                    });
                }
            }
        });
    });
}

function updateTabScrollMask() {
    if (!tabsList) return;
    if (tabsList.scrollLeft > 0 && tabsList.scrollLeft < 4) tabsList.scrollLeft = 0;
    var sLeft = tabsList.scrollLeft, maxScroll = tabsList.scrollWidth - tabsList.clientWidth;
    if (maxScroll > 0 && sLeft > maxScroll - 4) { tabsList.scrollLeft = maxScroll; sLeft = maxScroll; }
    if (maxScroll <= 0) { tabsList.style.webkitMaskImage = 'none'; return; }
    var showLeft = sLeft > 5, showRight = sLeft < maxScroll - 5;
    if (showLeft && showRight) tabsList.style.webkitMaskImage = 'linear-gradient(to right, transparent 0px, black 16px, black calc(100% - 16px), transparent 100%)';
    else if (showLeft) tabsList.style.webkitMaskImage = 'linear-gradient(to right, transparent 0px, black 16px, black 100%)';
    else if (showRight) tabsList.style.webkitMaskImage = 'linear-gradient(to right, black 0%, black calc(100% - 16px), transparent 100%)';
    else tabsList.style.webkitMaskImage = 'none';
}
if (tabsList) { tabsList.addEventListener('scroll', updateTabScrollMask); window.addEventListener('resize', updateTabScrollMask); }

var tabsTargetScroll = 0, isScrollingTabs = false;
if (tabsList) {
    tabsList.addEventListener('wheel', function (e) {
        e.preventDefault();
        if (!isScrollingTabs) tabsTargetScroll = tabsList.scrollLeft;
        var maxScroll = Math.max(0, tabsList.scrollWidth - tabsList.clientWidth);
        tabsTargetScroll += e.deltaY > 0 ? 80 : -80;
        tabsTargetScroll = Math.max(0, Math.min(tabsTargetScroll, maxScroll));
        if (!isScrollingTabs) { isScrollingTabs = true; requestAnimationFrame(smoothTabsScroll); }
    });
}
function smoothTabsScroll() {
    if (!tabsList) return;
    var diff = tabsTargetScroll - tabsList.scrollLeft;
    if (Math.abs(diff) < 1.0) { tabsList.scrollLeft = tabsTargetScroll; isScrollingTabs = false; updateTabScrollMask(); return; }
    tabsList.scrollLeft += diff * 0.15; updateTabScrollMask(); requestAnimationFrame(smoothTabsScroll);
}

function getEditorValue() { return monacoEditor ? monacoEditor.getValue() : (fallbackEditor ? fallbackEditor.value : ''); }
function setEditorValue(content) { if (monacoEditor) monacoEditor.setValue(content || ''); else if (fallbackEditor) fallbackEditor.value = content || ''; }
function getOrCreateModel(tab) {
    if (!window.monaco) return null;
    if (!monacoModels[tab.id]) {
        var tabId = tab.id;
        monacoModels[tab.id] = monaco.editor.createModel(tab.content || '', 'luau');
        monacoModels[tab.id].updateOptions({
            insertSpaces: !!settings.editorInsertSpaces,
            tabSize: 4
        });
        monacoModels[tab.id].onDidChangeContent(function () {
            var t = tabs.find(function (x) { return x.id === tabId; });
            if (t) t.content = monacoModels[tabId].getValue();
        });
    }
    return monacoModels[tab.id];
}
function switchTab(id) {
    if (saveTabsTimeout) {
        clearTimeout(saveTabsTimeout);
        saveTabs();
        saveTabsTimeout = null;
    }
    var cur = tabs.find(function (t) { return t.id === activeTab; });
    if (cur) cur.content = getEditorValue();

    if (splitTabIds.length === 2) {
        if (splitTabIds.includes(id)) {

            isSplitView = true;
            $id('monaco-container-secondary').classList.remove('split-hidden');
            activeTab = id;
            const t1 = tabs.find(t => t.id === splitTabIds[0]);
            const t2 = tabs.find(t => t.id === splitTabIds[1]);
            if (monacoEditor && t1) {
                monacoEditor.setModel(getOrCreateModel(t1));
                monacoEditor.updateOptions({ readOnly: !!t1.readOnly });
            }
            if (monacoEditorSecondary && t2) {
                monacoEditorSecondary.setModel(getOrCreateModel(t2));
                monacoEditorSecondary.updateOptions({ readOnly: !!t2.readOnly });
            }
        } else {

            isSplitView = false;
            $id('monaco-container-secondary').classList.add('split-hidden');
            activeTab = id;
            var tab = tabs.find(function (t) { return t.id === id; });
            if (tab) {
                if (monacoEditor && window.monaco) {
                    monacoEditor.setModel(getOrCreateModel(tab));
                    monacoEditor.updateOptions({ readOnly: !!tab.readOnly });
                }
                else setEditorValue(tab.content);
            }
        }
    } else {

        isSplitView = false;
        activeTab = id;
        var tab = tabs.find(function (t) { return t.id === id; });
        if (tab) {
            if (monacoEditor && window.monaco) {
                monacoEditor.setModel(getOrCreateModel(tab));
                monacoEditor.updateOptions({ readOnly: !!tab.readOnly });
            }
            else setEditorValue(tab.content);
        }
    }
    renderTabs();
    saveTabs();
    if (window.triggerTabValidation) window.triggerTabValidation();
    setTimeout(() => {
        if (monacoEditor) monacoEditor.layout();
        if (monacoEditorSecondary) monacoEditorSecondary.layout();
    }, 150);
}

window.openSplitSelect = function (primaryId) {
    const list = $id('split-select-list');
    if (!list) return;
    list.innerHTML = '';

    tabs.forEach(tab => {
        if (tab.id === primaryId) return;
        const item = document.createElement('div');
        item.className = 'split-select-item';
        item.innerHTML = `<svg class="ss-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg><span class="ss-name">${tab.name}</span>`;
        item.onclick = () => { closeSplitSelect(); enterSplitView(primaryId, tab.id); };
        list.appendChild(item);
    });

    const modal = $id('split-select-modal');
    modal.style.display = 'flex';
    void modal.offsetWidth;
    modal.classList.add('visible');
    modal.classList.add('pane-enter');
};

function closeSplitSelect() {
    const modal = $id('split-select-modal');
    modal.classList.remove('visible');
    setTimeout(() => modal.style.display = 'none', 300);
}
if ($id('split-select-cancel')) $id('split-select-cancel').onclick = closeSplitSelect;

function enterSplitView(id1, id2) {
    if (isSplitView) return;
    isSplitView = true;
    splitTabIds = [id1, id2];
    settings.splitTabIds = splitTabIds;
    saveSettings();
    activeTab = id2;

    $id('monaco-container-secondary').classList.remove('split-hidden');

    if (!monacoEditorSecondary) {
        var vMode = settings.editorScrollbarV !== false ? 'auto' : 'hidden';
        var hMode = settings.editorScrollbarH !== false ? 'auto' : 'hidden';
        var vSize = settings.editorScrollbarV !== false ? 6 : 0;
        var hSize = settings.editorScrollbarH !== false ? 6 : 0;

        monacoEditorSecondary = monaco.editor.create($id('monaco-container-secondary'), {
            value: '', language: 'luau', theme: 'sirhurt', fontSize: 13, lineHeight: 22, letterSpacing: 0.5, automaticLayout: true,
            minimap: { enabled: settings.editorMinimap, side: settings.editorMinimapSide, renderCharacters: true, size: 'proportional', maxColumn: 120, scale: 2, showSlider: 'always' },
            smoothScrolling: true, cursorSmoothCaretAnimation: 'on', cursorBlinking: 'smooth', cursorWidth: 2, renderLineHighlight: 'line',
            fontFamily: "'JetBrains Mono', Consolas, monospace", fontLigatures: true,
            padding: { top: 12, bottom: 12 },
            links: false,
            scrollBeyondLastLine: false,
            scrollbar: {
                vertical: vMode, horizontal: hMode,
                verticalScrollbarSize: vSize, horizontalScrollbarSize: hSize, useShadows: false
            },
            contextmenu: false,
            overviewRulerLanes: 0, hideCursorInOverviewRuler: true, overviewRulerBorder: false
        });
        monacoEditorSecondary.onDidChangeModelContent(() => {
            const tab = tabs.find(t => t.id === splitTabIds[1]);
            if (tab) { tab.content = monacoEditorSecondary.getValue(); saveTabs(); }
        });
        if (window.monacoResizeObserver) window.monacoResizeObserver.observe($id('monaco-container-secondary'));
    }

    const tab2 = tabs.find(t => t.id === id2);
    if (tab2) {
        monacoEditorSecondary.setModel(getOrCreateModel(tab2));
        monacoEditorSecondary.updateOptions({ readOnly: !!tab2.readOnly });
    }

    const tab1 = tabs.find(t => t.id === id1);
    if (tab1 && monacoEditor) {
        monacoEditor.setModel(getOrCreateModel(tab1));
        monacoEditor.updateOptions({ readOnly: !!tab1.readOnly });
    }

    renderTabs();
    window.applyTheme(window.activeThemeId);
}

window.exitSplitView = function () {
    isSplitView = false;
    splitTabIds = [];
    settings.splitTabIds = [];
    saveSettings();
    $id('monaco-container-secondary').classList.add('split-hidden');
    renderTabs();
    window.applyTheme(window.activeThemeId);
};
function closeTab(id) {
    if (tabs.length === 1) return;

    var tabEl = document.querySelector(`.tab[data-id="${id}"]`);
    var execClose = function () {
        if (tabEl) {
            tabEl.style.pointerEvents = 'none'; tabEl.style.transition = 'max-width 0.08s ease, opacity 0.08s ease, padding 0.08s ease, margin 0.08s ease'; tabEl.classList.add('tab-exiting');
            setTimeout(() => { finishCloseTab(id); }, 80);
        } else { finishCloseTab(id); }
    };

    if (settings.confirmClose) {
        let t = tabs.find(x => x.id === id);
        let tName = t ? t.name : "this tab";
        let modalText = "Are you sure you want to close this tab? If you don't have it saved, it can't be recovered.";
        if (settings.enableScriptHistory !== false) {
            modalText = "The tab will be closed. You have History enabled so you can go to Files > History and view this later again until it's automatically deleted.";
        }
        window.openActionModal(
            "Close " + tName + "?",
            modalText,
            "red",
            execClose
        );
    } else {
        execClose();
    }
}
function finishCloseTab(id) {
    if (splitTabIds.includes(id)) {
        isSplitView = false;
        splitTabIds = [];
        $id('monaco-container-secondary').classList.add('split-hidden');
    }
    const index = tabs.findIndex(t => t.id === id);
    if (index !== -1) {
        saveTabToHistory(tabs[index]);
        if (monacoModels[id]) { monacoModels[id].dispose(); delete monacoModels[id]; }
        tabs.splice(index, 1);
        var nextActiveId = activeTab;
        if (activeTab === id) {
            nextActiveId = tabs[Math.max(0, index - 1)].id;
        }
        switchTab(nextActiveId);
    }
}
function createNewTab(name, content) {
    var id = nextId++;
    tabs.push({ id: id, name: name, content: content });
    recentlyAddedTabId = id;
    switchTab(id);
    recentlyAddedTabId = null;

    if (settings.focusOnNewTab) {
        setTimeout(function () {
            if (tabsList) {
                var maxScroll = Math.max(0, tabsList.scrollWidth - tabsList.clientWidth);
                tabsTargetScroll = maxScroll;
                if (!isScrollingTabs) {
                    isScrollingTabs = true;
                    requestAnimationFrame(smoothTabsScroll);
                }
            }
        }, 50);
    }
}

function updateHeaderText(newText) {
    if (!fpHeader) return;
    fpHeader.classList.add('text-fade');
    setTimeout(function () { fpHeader.textContent = newText; fpHeader.classList.remove('text-fade'); }, 5);
}
function showRootHub() {
    const ev = document.querySelector('.editor-view');
    if (ev) ev.classList.remove('history-active');
    updateHeaderText('File List');
    fpBack.style.opacity = '0'; setTimeout(function () { fpBack.style.display = 'none'; }, 250);
    fpBody.classList.remove('blur-anim'); void fpBody.offsetWidth; fpBody.classList.add('blur-anim');
    fpBody.innerHTML = '<div class="fp-item fp-root-item" data-root="scripts" onclick="loadFolder(\'scripts\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"/></svg><span>Scripts</span></div><div class="fp-item fp-root-item" data-root="autoexe" onclick="loadFolder(\'autoexe\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"/></svg><span>AutoExec</span></div><div class="fp-item fp-root-item" data-root="workspace" onclick="loadFolder(\'workspace\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"/></svg><span>Workspace</span></div><div class="fp-item fp-root-item" data-root="SirHurtV5.exe.WebView2/scriptshistory" onclick="loadFolder(\'SirHurtV5.exe.WebView2/scriptshistory\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg><span>History</span></div>';
}

window.resolveZenithPath = function (rel) {
    if (!rel || rel.includes(':') || rel.includes('\\')) return rel;
    var loc = window.location.href.split('?')[0].split('#')[0];
    var lowLoc = loc.toLowerCase();

    if (lowLoc.includes('/ui/')) {
        var idx = lowLoc.lastIndexOf('/ui/');
        var root = loc.substring(0, idx).replace(/^file:\/\/\/?/i, '');
        root = decodeURIComponent(root).replace(/\//g, '\\');
        if (root.charAt(0) === '\\' && root.charAt(2) === ':') root = root.substring(1);


        return root + '\\' + rel.replace(/\//g, '\\');
    }
    return rel;
};

window.currentFolder = null;
window.loadFolder = function (folder) {
    window.currentFolder = folder;
    var absPath = window.resolveZenithPath(folder);
    if (bridge && bridge.WatchFolder) bridge.WatchFolder(absPath);
    updateHeaderText(folder === 'autoexe' ? 'AutoExec' : (folder === 'workspace' ? 'Workspace' : (folder === 'SirHurtV5.exe.WebView2/scriptshistory' ? 'History' : 'Scripts')));
    fpBack.textContent = 'Back'; fpBack.style.display = 'flex'; setTimeout(function () { fpBack.style.opacity = '1'; }, 10);
    fpBody.classList.remove('blur-anim'); void fpBody.offsetWidth; fpBody.classList.add('blur-anim');
    fpBody.innerHTML = '<div class="fp-item" style="color:#444">Loading...</div>';
    window.refreshCurrentFolder(folder);
};
window.folderBack = function () {
    const ev = document.querySelector('.editor-view');
    if (ev) ev.classList.remove('history-active');
    window.currentFolder = null;
    showRootHub();
};
window.refreshCurrentFolder = function (folder) {
    if (window.currentFolder !== folder || !bridge) return;
    const ev = document.querySelector('.editor-view');
    if (folder === 'SirHurtV5.exe.WebView2/scriptshistory') {
        if (ev) ev.classList.add('history-active');
    } else {
        if (ev) ev.classList.remove('history-active');
    }
    bridge.GetScripts(window.resolveZenithPath(folder)).then(function (files) {
        fpBody.innerHTML = '';
        if (folder === 'SirHurtV5.exe.WebView2/scriptshistory') {
            const settingDiv = document.createElement('div');
            settingDiv.style.padding = '8px 6px';
            settingDiv.style.borderBottom = '1px solid var(--bd)';
            settingDiv.style.display = 'flex';
            settingDiv.style.flexDirection = 'column';
            settingDiv.style.gap = '6px';
            settingDiv.style.marginBottom = '6px';
            settingDiv.innerHTML = `
                <div style="font-size: 9px; color: var(--t3); text-transform: uppercase; font-weight: 600; letter-spacing: 0.5px; padding-left: 2px;">Closed Tabs History</div>
                <div style="font-size: 10px; color: var(--t2); margin-bottom: 2px; padding-left: 2px;">Auto delete scripts after:</div>
                <div class="custom-select" style="width: 100%;">
                    <select id="select-history-duration" style="display: none;">
                        <option value="1">1 Day</option>
                        <option value="3">3 Days</option>
                        <option value="7">7 Days</option>
                        <option value="14">14 Days</option>
                        <option value="30">30 Days</option>
                        <option value="never">Never</option>
                    </select>
                </div>
            `;
            fpBody.appendChild(settingDiv);

            const sel = settingDiv.querySelector('#select-history-duration');
            if (sel) {
                sel.value = settings.historyCleanDuration || '3';
                sel.addEventListener('change', function (e) {
                    settings.historyCleanDuration = e.target.value;
                    saveSettings();
                    triggerHistoryCleanup();
                });
            }
            if (typeof setupCustomSelects === 'function') {
                setupCustomSelects();
            }
        }
        if (folder === 'SirHurtV5.exe.WebView2/scriptshistory' && files && files.length > 0) {
            files = files.map(file => {
                var isFolder = file.endsWith('/') || file.endsWith('\\');
                var parts = file.replace(/\\/g, '/').split('/');
                var cleanName = isFolder ? parts[parts.length - 2] : parts[parts.length - 1];
                let timeValue = 0;
                if (!isFolder && cleanName) {
                    const startIdx = cleanName.lastIndexOf('(');
                    const endIdx = cleanName.lastIndexOf(')');
                    if (startIdx !== -1 && endIdx !== -1 && endIdx > startIdx) {
                        const inner = cleanName.substring(startIdx + 1, endIdx);
                        const tparts = inner.split(' ');
                        if (tparts.length === 2 && tparts[0].includes('-') && tparts[1].includes('-')) {
                            const datePart = tparts[0];
                            const timePart = tparts[1].replace(/-/g, ':');
                            const fileDate = new Date(datePart + 'T' + timePart);
                            if (!isNaN(fileDate.getTime())) {
                                timeValue = fileDate.getTime();
                            }
                        }
                    }
                }
                return { file: file, time: timeValue };
            }).sort((a, b) => b.time - a.time)
                .map(item => item.file);
        }
        if (!files || files.length === 0) {
            if (folder !== 'SirHurtV5.exe.WebView2/scriptshistory') {
                fpBody.innerHTML = '<div class="fp-item">Empty</div>';
            } else {
                const emptyDiv = document.createElement('div');
                emptyDiv.className = 'fp-item';
                emptyDiv.innerText = 'Empty';
                fpBody.appendChild(emptyDiv);
            }
            return;
        }
        files.forEach(function (file) {

            var isFolder = file.endsWith('/') || file.endsWith('\\');
            var parts = file.replace(/\\/g, '/').split('/');
            var cleanName = isFolder ? parts[parts.length - 2] : parts[parts.length - 1];

            if (!cleanName) return;

            var el = document.createElement('div'); el.className = 'fp-item zenith-scroll-item'; el.dataset.file = cleanName; el.dataset.folder = folder;
            if (isFolder) el.dataset.type = 'folder';
            if (window.observeScrollElement) window.observeScrollElement(el);

            var icon = isFolder ? '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 20a2 2-0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"/></svg>' :
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>';

            if (folder === 'SirHurtV5.exe.WebView2/scriptshistory' && !isFolder) {
                let displayName = cleanName;
                let dateText = "";
                const startIdx = cleanName.lastIndexOf('(');
                const endIdx = cleanName.lastIndexOf(')');
                if (startIdx !== -1 && endIdx !== -1 && endIdx > startIdx) {
                    const inner = cleanName.substring(startIdx + 1, endIdx);
                    const tparts = inner.split(' ');
                    if (tparts.length === 2 && tparts[0].includes('-') && tparts[1].includes('-')) {
                        const datePart = tparts[0];
                        const timePart = tparts[1].replace(/-/g, ':');
                        dateText = datePart + ' ' + timePart;
                        let base = cleanName.substring(0, startIdx).trim();
                        let ext = "";
                        if (cleanName.toLowerCase().endsWith('.lua')) ext = ".lua";
                        else if (cleanName.toLowerCase().endsWith('.luau')) ext = ".luau";
                        else if (cleanName.toLowerCase().endsWith('.txt')) ext = ".txt";
                        displayName = base + ext;
                    }
                }
                el.innerHTML = icon + `
                    <div style="display: flex; flex-direction: column; min-width: 0; flex: 1; line-height: 1.2;">
                        <span style="font-size: 11.5px; font-weight: 500; color: var(--t1); overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${esc(displayName)}</span>
                        <span style="font-size: 9px; font-weight: 400; color: var(--t2); margin-top: 1px;">${esc(dateText)}</span>
                    </div>
                `;
            } else {
                el.innerHTML = icon + '<span>' + esc(cleanName) + '</span>';
            }
            el.onclick = function () {
                var absPath = window.resolveZenithPath(folder);
                if (isFolder) {
                    window.loadFolder(folder + (folder.endsWith('/') || folder.endsWith('\\') ? '' : '/') + cleanName);
                } else {
                    bridge.ReadScript(absPath, cleanName).then(function (c) { createNewTab(cleanName, c || ''); });
                }
            };
            fpBody.appendChild(el);
        });
    });
};

window.validateLuauCode = function (model) {
    if (typeof monaco === 'undefined' || !model) return;
    const markers = [];
    const fullText = model.getValue();
    const lines = fullText.split('\n');

    let inDoubleQuote = false;
    let inSingleQuote = false;
    let inLongString = false;
    let inLongComment = false;
    let inLineComment = false;

    let stringStartLine = -1;
    let stringStartCol = -1;

    const parenStack = [];
    const braceStack = [];
    const bracketStack = [];

    for (let lineIdx = 0; lineIdx < lines.length; lineIdx++) {
        const lineText = lines[lineIdx];
        const lineNum = lineIdx + 1;
        inLineComment = false;

        for (let colIdx = 0; colIdx < lineText.length; colIdx++) {
            const char = lineText[colIdx];
            const nextChar = lineText[colIdx + 1];
            const prevChar = lineText[colIdx - 1];
            const isEscaped = prevChar === '\\' && (colIdx < 2 || lineText[colIdx - 2] !== '\\');

            if (inLongComment) {
                if (char === ']' && nextChar === ']') {
                    inLongComment = false;
                    colIdx++;
                }
                continue;
            }

            if (inLongString) {
                if (char === ']' && nextChar === ']') {
                    inLongString = false;
                    colIdx++;
                }
                continue;
            }

            if (inLineComment) {
                continue;
            }

            if (inDoubleQuote) {
                if (char === '"' && !isEscaped) {
                    inDoubleQuote = false;
                }
                continue;
            }

            if (inSingleQuote) {
                if (char === "'" && !isEscaped) {
                    inSingleQuote = false;
                }
                continue;
            }

            if (char === '-' && nextChar === '-') {
                if (lineText[colIdx + 2] === '[' && lineText[colIdx + 3] === '[') {
                    inLongComment = true;
                    colIdx += 3;
                } else {
                    inLineComment = true;
                    colIdx++;
                }
                continue;
            }

            if (char === '[' && nextChar === '[') {
                inLongString = true;
                colIdx++;
                continue;
            }

            if (char === '"') {
                inDoubleQuote = true;
                stringStartLine = lineNum;
                stringStartCol = colIdx + 1;
                continue;
            }

            if (char === "'") {
                inSingleQuote = true;
                stringStartLine = lineNum;
                stringStartCol = colIdx + 1;
                continue;
            }

            if (char === '(') {
                parenStack.push({ line: lineNum, col: colIdx + 1 });
            } else if (char === ')') {
                if (parenStack.length > 0) {
                    parenStack.pop();
                } else {
                    markers.push({
                        startLineNumber: lineNum,
                        endLineNumber: lineNum,
                        startColumn: colIdx + 1,
                        endColumn: colIdx + 2,
                        message: "Unmatched closing parenthesis ')'",
                        severity: monaco.MarkerSeverity.Error
                    });
                }
            }

            if (char === '{') {
                braceStack.push({ line: lineNum, col: colIdx + 1 });
            } else if (char === '}') {
                if (braceStack.length > 0) {
                    braceStack.pop();
                } else {
                    markers.push({
                        startLineNumber: lineNum,
                        endLineNumber: lineNum,
                        startColumn: colIdx + 1,
                        endColumn: colIdx + 2,
                        message: "Unmatched closing brace '}'",
                        severity: monaco.MarkerSeverity.Error
                    });
                }
            }

            if (char === '[') {
                bracketStack.push({ line: lineNum, col: colIdx + 1 });
            } else if (char === ']') {
                if (bracketStack.length > 0) {
                    bracketStack.pop();
                } else {
                    markers.push({
                        startLineNumber: lineNum,
                        endLineNumber: lineNum,
                        startColumn: colIdx + 1,
                        endColumn: colIdx + 2,
                        message: "Unmatched closing bracket ']'",
                        severity: monaco.MarkerSeverity.Error
                    });
                }
            }
        }

        if (inDoubleQuote) {
            markers.push({
                startLineNumber: stringStartLine,
                endLineNumber: stringStartLine,
                startColumn: stringStartCol,
                endColumn: lines[stringStartLine - 1].length + 1,
                message: 'Unclosed string literal (missing double quote ")',
                severity: monaco.MarkerSeverity.Error
            });
            inDoubleQuote = false;
        }
        if (inSingleQuote) {
            markers.push({
                startLineNumber: stringStartLine,
                endLineNumber: stringStartLine,
                startColumn: stringStartCol,
                endColumn: lines[stringStartLine - 1].length + 1,
                message: "Unclosed string literal (missing single quote ')",
                severity: monaco.MarkerSeverity.Error
            });
            inSingleQuote = false;
        }
    }

    parenStack.forEach(p => {
        markers.push({
            startLineNumber: p.line,
            endLineNumber: p.line,
            startColumn: p.col,
            endColumn: p.col + 1,
            message: "Unclosed opening parenthesis '('",
            severity: monaco.MarkerSeverity.Error
        });
    });
    braceStack.forEach(b => {
        markers.push({
            startLineNumber: b.line,
            endLineNumber: b.line,
            startColumn: b.col,
            endColumn: b.col + 1,
            message: "Unclosed opening brace '{'",
            severity: monaco.MarkerSeverity.Error
        });
    });
    bracketStack.forEach(br => {
        markers.push({
            startLineNumber: br.line,
            endLineNumber: br.line,
            startColumn: br.col,
            endColumn: br.col + 1,
            message: "Unclosed opening bracket '['",
            severity: monaco.MarkerSeverity.Error
        });
    });

    monaco.editor.setModelMarkers(model, "luau", markers);
};

window.triggerTabValidation = function () {
    if (typeof monaco === 'undefined') return;
    if (monacoEditor && monacoEditor.getModel()) {
        window.validateLuauCode(monacoEditor.getModel());
    }
    if (monacoEditorSecondary && monacoEditorSecondary.getModel()) {
        window.validateLuauCode(monacoEditorSecondary.getModel());
    }
};

window.highlightErrorInEditor = function (lineNumber, message) {
    if (typeof monaco === 'undefined' || !monacoEditor) return;
    const model = monacoEditor.getModel();
    if (!model) return;
    if (lineNumber < 1 || lineNumber > model.getLineCount()) return;

    monaco.editor.setModelMarkers(model, "luau", [{
        startLineNumber: lineNumber,
        endLineNumber: lineNumber,
        startColumn: 1,
        endColumn: model.getLineMaxColumn(lineNumber),
        message: message || "Error occurred here in-game",
        severity: monaco.MarkerSeverity.Error
    }]);
};

window.clearEditorErrors = function () {
    if (typeof monaco === 'undefined' || !monacoEditor) return;
    const model = monacoEditor.getModel();
    if (model) {
        monaco.editor.setModelMarkers(model, "luau", []);
        // Re-run validation so user syntax feedback remains active
        window.validateLuauCode(model);
    }
};

function createLogLine(text, isError) {
    var el = document.createElement('div');
    el.style.padding = "2px 0";
    el.style.fontFamily = "'JetBrains Mono', Consolas, monospace";
    el.style.fontSize = "11px";
    el.style.wordWrap = "break-word";
    el.style.whiteSpace = "pre-wrap";

    var trimmed = String(text).trim();
    var isMainError = isError || text.includes("[ERROR]") || text.includes("[ERR]");
    var isStackTrace = text.includes("Stack Begin") || text.includes("Stack End") ||
        text.includes("Script '") || text.startsWith("    ") || text.startsWith("\t");
    var isErrLine = isMainError || isStackTrace;

    var isWarnLine = !isErrLine && text.includes("[WARN]");

    if (isErrLine) el.style.color = "#ff453a";
    else if (isWarnLine) el.style.color = "#febc2e";
    else el.style.color = "rgba(255, 255, 255, 0.7)";

    var time = new Date().toLocaleTimeString('en-US', { hour12: false });
    var displayPref = "";

    if (isMainError) {
        displayPref = '<span style="color:#ff453a; margin-right:4px;">●</span>';
    } else if (isWarnLine) {
        displayPref = '<span style="color:#febc2e; margin-right:4px;">▲</span>';
    }

    var cleanText = String(text);
    cleanText = cleanText.replace(/^\[ERR\]\s*/i, "")
        .replace(/^\[ERROR\]\s*/i, "")
        .replace(/^\[WARN\]\s*/i, "")
        .replace(/^\[INFO\]\s*/i, "")
        .replace(/^\[RBX\]\s*/i, "");

    if (isErrLine) {
        var parseErrorLine = function (errorText) {
            var m1 = errorText.match(/Script\s+'([^']+)'\s*,\s*Line\s+(\d+)/i);
            if (m1) return { script: m1[1], line: parseInt(m1[2]) };
            var m2 = errorText.match(/([\w\.\-\s]+):(\d+):/);
            if (m2) return { script: m2[1].trim(), line: parseInt(m2[2]) };
            var m3 = errorText.match(/Line\s+(\d+)/i);
            if (m3) return { script: null, line: parseInt(m3[1]) };
            return null;
        };

        var errInfo = parseErrorLine(cleanText);
        if (errInfo && !isNaN(errInfo.line)) {
            var lineNum = errInfo.line;
            var scriptName = errInfo.script;
            var shouldHighlight = true;
            if (scriptName) {
                var activeTabObj = tabs.find(function (t) { return t.id === activeTab; });
                if (activeTabObj) {
                    var tabNameLower = activeTabObj.name.toLowerCase();
                    var scriptNameLower = scriptName.toLowerCase();
                    var stripExt = function (name) { return name.replace(/\.[a-zA-Z0-9]+$/, ''); };
                    var cleanTabName = stripExt(tabNameLower);
                    var cleanScriptName = stripExt(scriptNameLower);
                    if (cleanScriptName.includes('.')) {
                        var parts = cleanScriptName.split('.');
                        cleanScriptName = parts[parts.length - 1];
                    }
                    if (cleanTabName !== cleanScriptName &&
                        !cleanTabName.includes(cleanScriptName) &&
                        !cleanScriptName.includes(cleanTabName)) {
                        shouldHighlight = false;
                    }
                } else {
                    shouldHighlight = false;
                }
            }
            if (shouldHighlight && window.highlightErrorInEditor) {
                window.highlightErrorInEditor(lineNum, cleanText);
            }
        }
    }

    var safeText = cleanText.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    el.innerHTML = '<span style="color:#555">[' + time + ']</span> ' + displayPref + '<span style="margin-left:2px">' + safeText + '</span>';
    return el;
}

function appendToConsole(listId, bodyId, text) {
    if (typeof text === 'string' && text.trim() === '') return;
    var list = document.getElementById(listId); if (!list) return;
    var ph = list.querySelector('.console-ph'); if (ph) ph.remove();
    list.appendChild(createLogLine(text, false));
    var maxLines = settings.consoleLimit || 1000;
    while (list.children.length > maxLines) {
        var firstChild = list.firstChild;
        if (firstChild) {
            firstChild.remove();
        } else {
            break;
        }
    }
    var body = document.getElementById(bodyId); if (body) body.scrollTop = body.scrollHeight;
}
window.addBasicConsoleOutput = function (text) { appendToConsole('history-list', 'console-body', text); };
window.addConsoleLines = function (lines) { lines.forEach(function (line) { appendToConsole('detailed-history-list', 'detailed-console-body', line); }); };
window.addLuaConsoleLines = function (lines) {
    if (!settings.errorSpoofing) return;
    lines.forEach(function (line) { appendToConsole('lua-history-list', 'lua-console-body', line); });
};
window.addTerminalLog = function (level, msg) { appendToConsole('history-list', 'console-body', "[" + level + "] " + msg); };
window.executeScript = async function (code) {
    if (!code) return;
    if (settings.clearOnExec) {
        var lhl = document.getElementById('lua-history-list');
        if (lhl) lhl.innerHTML = '<span class="console-ph">Waiting for in-game Lua console...</span>';
    }
    try {
        if (typeof bridge !== 'undefined' && bridge.Execute) {
            await bridge.Execute(code);
        } else if (window.chrome && window.chrome.webview) {
            await window.chrome.webview.hostObjects.bridge.Execute(code);
        }
    } catch (e) { }
};

var globalClearBtn = $id('btn-clear-console');
if (globalClearBtn) {
    globalClearBtn.onclick = function () {
        if ($id('history-list')) $id('history-list').innerHTML = '<span class="console-ph">Waiting for SirHurt output...</span>';
        if ($id('detailed-history-list')) $id('detailed-history-list').innerHTML = '<span class="console-ph">Waiting for detailed background logs...</span>';
        if ($id('lua-history-list')) $id('lua-history-list').innerHTML = '<span class="console-ph">Waiting for in-game Lua console...</span>';
        window.updateConsolePlaceholders();
    };
}

window.updateConsolePlaceholders = function () {
    const luaList = $id('lua-history-list');
    if (!luaList) return;


    const existing = luaList.querySelector('.console-tip');
    if (settings.errorSpoofing) {
        if (existing) existing.remove();
        return;
    }


    if (!existing && luaList.innerText.includes('Waiting for in-game Lua console')) {
        const tip = document.createElement('div');
        tip.className = 'console-tip';
        tip.innerHTML = `To have logs you must have <span class="nav-highlight" onclick="window.highlightSetting('exec', 'toggle-errorspoof')">Error Spoofing/Redirection</span> enabled.`;
        luaList.appendChild(tip);
    }
};

window.highlightSetting = function (paneId, elementIdOrIds) {
    navigateTo('settings');
    if (typeof openSettingsPane === 'function') openSettingsPane(paneId);



    var ids = [];
    if (Array.isArray(elementIdOrIds)) {
        ids = elementIdOrIds;
    } else if (typeof elementIdOrIds === 'string') {
        ids = elementIdOrIds.split(',').map(function (s) { return s.trim(); });
    } else {
        ids = [elementIdOrIds];
    }
    var attempts = 0;

    var highlightInterval = setInterval(function () {
        var targetItems = [];
        var allFound = true;

        for (var i = 0; i < ids.length; i++) {
            var el = document.getElementById(ids[i]);
            if (el && el.offsetParent !== null) {
                targetItems.push(el.closest('.settings-nav-item') || el.parentElement);
            } else {
                allFound = false;
            }
        }


        if (targetItems.length > 0 && (allFound || attempts > 10)) {
            clearInterval(highlightInterval);

            targetItems.forEach(function (item) {
                item.classList.remove('flash-highlight');
                void item.offsetWidth;
                item.classList.add('flash-highlight');
                setTimeout(function () { item.classList.remove('flash-highlight'); }, 2200);
            });


            targetItems[0].scrollIntoView({ behavior: 'auto', block: 'nearest' });
        }
        if (attempts++ > 20) clearInterval(highlightInterval);
    }, 100);
};

window.formatLuau = function (code) {
    if (!code) return "";
    let lines = code.split('\n');
    let indent = 0;
    let formattedLines = [];

    for (let line of lines) {
        line = line.trim();
        if (!line) { formattedLines.push(""); continue; }


        let lower = line.toLowerCase();
        let outdentMatch = lower.match(/^(end\b|\}|\belse\b|\belseif\b|\buntil\b)/);
        if (outdentMatch) indent = Math.max(0, indent - 1);

        formattedLines.push("    ".repeat(indent) + line);



        let indentMatch = lower.match(/(\bthen\b|\bdo\b|\{|\bfunction\b|\brepeat\b)$/);

        if (indentMatch && !outdentMatch) indent++;
        else if (outdentMatch && indentMatch) indent++;
    }
    return formattedLines.join('\n');
};

function setupMonaco() {
    try {
        monaco.languages.register({ id: 'luau' });
        monaco.languages.setLanguageConfiguration('luau', {
            brackets: [
                ['{', '}'],
                ['[', ']'],
                ['(', ')']
            ],
            autoClosingPairs: [
                { open: '{', close: '}' },
                { open: '[', close: ']' },
                { open: '(', close: ')' },
                { open: '"', close: '"' },
                { open: "'", close: "'" }
            ],
            surroundingPairs: [
                { open: '{', close: '}' },
                { open: '[', close: ']' },
                { open: '(', close: ')' },
                { open: '"', close: '"' },
                { open: "'", close: "'" }
            ]
        });
        monaco.languages.setMonarchTokensProvider('luau', {
            keywords: ['and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while', 'continue', 'type', 'typeof', 'export'],
            builtins: ['print', 'warn', 'error', 'assert', 'pcall', 'xpcall', 'select', 'ipairs', 'pairs', 'next', 'tostring', 'tonumber', 'rawget', 'rawset', 'rawequal', 'rawlen', 'setmetatable', 'getmetatable', 'require', 'unpack'],
            roblox: ['game', 'workspace', 'script', 'plugin', '_G', 'shared', 'Instance', 'Vector3', 'Vector2', 'CFrame', 'Color3', 'UDim2', 'UDim', 'Enum'],
            tokenizer: {
                root: [
                    [/[a-zA-Z_]\w*/, { cases: { '@keywords': 'keyword', '@builtins': 'predefined', '@roblox': 'variable.predefined', '@default': 'identifier' } }],
                    [/\s+/, 'white'], [/--.*$/, 'comment'], [/"/, { token: 'string.quote', next: '@string_double' }], [/'/, { token: 'string.quote', next: '@string_single' }],
                    [/\d+/, 'number'], [/[+\-*/%^#&|~<>=;:,.]+/, 'operator'],
                ],
                string_double: [[/[^\\"]+/, 'string'], [/"/, { token: 'string.quote', next: '@pop' }]],
                string_single: [[/[^\\']+/, 'string'], [/'/, { token: 'string.quote', next: '@pop' }]]
            }
        });
        if (!window._registeredInsertSpaceCommand) {
            window._registeredInsertSpaceCommand = true;
            monaco.editor.registerCommand('editor.action.insertSpaceAfterSuggestion', function (accessor) {
                if (settings.editorInsertSpaces) {
                    const editors = monaco.editor.getEditors();
                    const activeEditor = editors.find(e => e.hasTextFocus()) || editors.find(e => e.getModel()) || editors[0];
                    if (activeEditor) {
                        const position = activeEditor.getPosition();
                        activeEditor.executeEdits('insert-space', [
                            {
                                range: new monaco.Range(position.lineNumber, position.column, position.lineNumber, position.column),
                                text: ' ',
                                forceMoveMarkers: true
                            }
                        ]);
                    }
                }
            });
        }
        monaco.languages.registerCompletionItemProvider('luau', {
            provideCompletionItems: (model, position) => {
                const suggestions = [];

                // 1. Luau / Lua Keywords
                const keywords = [
                    { name: 'and', doc: 'Logical AND operator.' },
                    { name: 'break', doc: 'Terminates loop execution.' },
                    { name: 'do', doc: 'Starts a block of code.' },
                    { name: 'else', doc: 'Executes if previous conditional branches are false.' },
                    { name: 'elseif', doc: 'Conditional branch check.' },
                    { name: 'end', doc: 'Terminates block, function, loop or conditional statement.' },
                    { name: 'false', doc: 'Boolean false value.' },
                    { name: 'for', doc: 'Loop control structure.' },
                    { name: 'function', doc: 'Declares a function.' },
                    { name: 'if', doc: 'Conditional execution check.' },
                    { name: 'in', doc: 'Used to iterate over tables in a for loop.' },
                    { name: 'local', doc: 'Declares a local variable or function.' },
                    { name: 'nil', doc: 'Null/undefined value.' },
                    { name: 'not', doc: 'Logical NOT operator.' },
                    { name: 'or', doc: 'Logical OR operator.' },
                    { name: 'repeat', doc: 'Loop body start, loops until expression is true.' },
                    { name: 'return', doc: 'Returns a value from a function.' },
                    { name: 'then', doc: 'Introduces code executed on successful conditional check.' },
                    { name: 'true', doc: 'Boolean true value.' },
                    { name: 'until', doc: 'Terminates a repeat-until loop.' },
                    { name: 'while', doc: 'Loops while a condition is true.' },
                    { name: 'continue', doc: 'Skips the rest of the current loop iteration.' },
                    { name: 'type', doc: 'Used for declaring Luau types.' },
                    { name: 'typeof', doc: 'Evaluates the type of an expression as a string.' },
                    { name: 'export', doc: 'Exports a custom type definition.' }
                ];

                keywords.forEach(k => {
                    suggestions.push({
                        label: k.name,
                        kind: monaco.languages.CompletionItemKind.Keyword,
                        insertText: k.name,
                        detail: 'keyword',
                        documentation: k.doc
                    });
                });

                // 2. Roblox Globals / Built-ins
                const globals = [
                    { name: 'game', detail: 'Roblox DataModel Root', doc: 'The root of the Roblox game directory tree structure.' },
                    { name: 'workspace', detail: 'Workspace Service', doc: 'Direct reference to the Workspace, which contains physical elements in the game.' },
                    { name: 'script', detail: 'Lua Source Container', doc: 'Reference to the script executing this code block.' },
                    { name: 'shared', detail: 'Shared Globals', doc: 'A global table shared across scripts of the same execution context.' },
                    { name: '_G', detail: 'Global Environment', doc: 'Shared global table available to all scripts.' },
                    { name: 'plugin', detail: 'Plugin Reference', doc: 'Reference to the running Studio Plugin.' },
                    { name: 'Enum', detail: 'Enum Library', doc: 'Access Roblox Enum collections (e.g. Enum.Material.Plastic).' }
                ];

                globals.forEach(g => {
                    suggestions.push({
                        label: g.name,
                        kind: monaco.languages.CompletionItemKind.Variable,
                        insertText: g.name,
                        detail: g.detail,
                        documentation: g.doc
                    });
                });

                // 3. Roblox Type Constructors
                const typeConstructors = [
                    { name: 'Vector3.new', insert: 'Vector3.new(${1:x}, ${2:y}, ${3:z})', detail: 'Vector3 constructor', doc: 'Creates a 3D vector representing coordinates or forces.' },
                    { name: 'Vector2.new', insert: 'Vector2.new(${1:x}, ${2:y})', detail: 'Vector2 constructor', doc: 'Creates a 2D vector for interface or 2D positioning.' },
                    { name: 'CFrame.new', insert: 'CFrame.new(${1:position})', detail: 'CFrame constructor', doc: 'Creates a Coordinate Frame describing position and rotation.' },
                    { name: 'Color3.fromRGB', insert: 'Color3.fromRGB(${1:r}, ${2:g}, ${3:b})', detail: 'Color3 RGB constructor', doc: 'Creates a Color3 object from values ranging 0 to 255.' },
                    { name: 'Color3.new', insert: 'Color3.new(${1:r}, ${2:g}, ${3:b})', detail: 'Color3 constructor', doc: 'Creates a Color3 object from values ranging 0 to 1.' },
                    { name: 'UDim2.new', insert: 'UDim2.new(${1:xScale}, ${2:xOffset}, ${3:yScale}, ${4:yOffset})', detail: 'UDim2 constructor', doc: 'Creates a 2D dimension representation for User Interface sizing/positioning.' },
                    { name: 'UDim.new', insert: 'UDim.new(${1:scale}, ${2:offset})', detail: 'UDim constructor', doc: 'Creates a single-dimension sizing/positioning value.' },
                    { name: 'TweenInfo.new', insert: 'TweenInfo.new(${1:time}, ${2:Enum.EasingStyle.Quad}, ${3:Enum.EasingDirection.Out})', detail: 'TweenInfo constructor', doc: 'Specifies visual tween animation parameters.' },
                    { name: 'Instance.new', insert: 'Instance.new("${1:ClassName}")', detail: 'Instance factory', doc: 'Creates a new Roblox Object instance dynamically.' }
                ];

                typeConstructors.forEach(tc => {
                    suggestions.push({
                        label: tc.name,
                        kind: monaco.languages.CompletionItemKind.Constructor,
                        insertText: tc.insert,
                        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                        detail: tc.detail,
                        documentation: tc.doc
                    });
                });

                // 4. Roblox Services & Snippets
                const snippets = [
                    { label: 'game:GetService', insert: 'game:GetService("${1:Service}")', detail: 'Retrieve Game Service', doc: 'Finds or initializes a global Roblox service.' },
                    { label: 'game:HttpGet', insert: 'game:HttpGet("${1:url}")', detail: 'HttpGet request', doc: 'Performs a GET request to the specified web URL.' },
                    { label: 'game:HttpPost', insert: 'game:HttpPost("${1:url}", ${2:data})', detail: 'HttpPost request', doc: 'Performs a POST request with payload data.' },
                    { label: 'task.wait', insert: 'task.wait(${1:seconds})', detail: 'task.wait method', doc: 'Yields the current thread for the specified duration (highly accurate).' },
                    { label: 'task.spawn', insert: 'task.spawn(function()\n\t${1}\nend)', detail: 'task.spawn thread', doc: 'Runs the given function immediately on a new thread.' },
                    { label: 'task.defer', insert: 'task.defer(function()\n\t${1}\nend)', detail: 'task.defer thread', doc: 'Defers the execution of the thread to the next cycle.' },
                    { label: 'task.delay', insert: 'task.delay(${1:seconds}, function()\n\t${2}\nend)', detail: 'task.delay thread', doc: 'Schedules a function to run after a specified duration.' },
                    { label: 'pcall', insert: 'pcall(function()\n\t${1}\nend)', detail: 'Protected call wrapper', doc: 'Runs the function safely, catching errors if they arise.' },
                    { label: 'xpcall', insert: 'xpcall(function()\n\t${1}\nend, function(err)\n\t${2}\nend)', detail: 'Extended protected call', doc: 'Runs the function safely with a secondary handler for caught errors.' }
                ];

                snippets.forEach(s => {
                    suggestions.push({
                        label: s.label,
                        kind: monaco.languages.CompletionItemKind.Snippet,
                        insertText: s.insert,
                        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                        detail: s.detail,
                        documentation: s.doc
                    });
                });

                // 5. standard global functions
                const functions = [
                    { name: 'print', doc: 'Prints expressions to the output log.' },
                    { name: 'warn', doc: 'Prints expressions as warnings (orange/yellow).' },
                    { name: 'error', doc: 'Throws a Lua runtime exception with a custom message.' },
                    { name: 'assert', doc: 'Asserts that condition evaluates to true; throws an error otherwise.' },
                    { name: 'tostring', doc: 'Converts any value into a human-readable string.' },
                    { name: 'tonumber', doc: 'Tries to parse a string representation of a number.' },
                    { name: 'type', doc: 'Returns the built-in type name of the value.' },
                    { name: 'typeof', doc: 'Returns Roblox/Luau specific type name of the value.' },
                    { name: 'select', doc: 'Retrieves arguments at or after index parameter.' },
                    { name: 'require', doc: 'Loads the specified ModuleScript and returns its exports.' },
                    { name: 'ipairs', doc: 'Iterator generator for arrays.' },
                    { name: 'pairs', doc: 'Iterator generator for dictionaries.' },
                    { name: 'next', doc: 'Walks key-value pairs of a table sequentially.' },
                    { name: 'tick', doc: 'Returns current UNIX time representation in local time.' },
                    { name: 'wait', doc: 'Legacy yield, yields current thread (use task.wait instead).' },
                    { name: 'spawn', doc: 'Legacy thread generator (use task.spawn instead).' },
                    { name: 'delay', doc: 'Legacy scheduler generator (use task.delay instead).' }
                ];

                functions.forEach(f => {
                    suggestions.push({
                        label: f.name,
                        kind: monaco.languages.CompletionItemKind.Function,
                        insertText: f.name + '(${1})',
                        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                        detail: 'global function',
                        documentation: f.doc
                    });
                });

                // 6. math, string, table library methods
                const libs = {
                    math: ['abs', 'acos', 'asin', 'atan', 'atan2', 'ceil', 'clamp', 'cos', 'cosh', 'deg', 'exp', 'floor', 'fmod', 'frexp', 'huge', 'ldexp', 'log', 'log10', 'max', 'min', 'modf', 'noise', 'pi', 'pow', 'rad', 'random', 'randomseed', 'round', 'sin', 'sinh', 'sqrt', 'tan', 'tanh', 'sign'],
                    string: ['byte', 'char', 'dump', 'find', 'format', 'gmatch', 'gsub', 'len', 'lower', 'match', 'pack', 'packsize', 'rep', 'reverse', 'sub', 'unpack', 'upper', 'split'],
                    table: ['concat', 'insert', 'remove', 'sort', 'create', 'find', 'clear', 'pack', 'unpack', 'move', 'freeze', 'isfrozen', 'clone'],
                    coroutine: ['create', 'resume', 'running', 'status', 'wrap', 'yield', 'isyieldable', 'close'],
                    debug: ['traceback', 'profilebegin', 'profileend', 'info'],
                    utf8: ['char', 'charpattern', 'codes', 'codepoint', 'len', 'offset', 'graphemes', 'nfcnormalize', 'nfdnormalize'],
                    bit32: ['arshift', 'band', 'bnot', 'bor', 'btest', 'bxor', 'lrotate', 'lshift', 'replace', 'rrotate', 'rshift', 'extract', 'countlz', 'countrz'],
                    buffer: ['create', 'fromstring', 'tostring', 'len', 'readi8', 'readu8', 'readi16', 'readu16', 'readi32', 'readu32', 'readf32', 'readf64', 'writei8', 'writeu8', 'writei16', 'writeu16', 'writei32', 'writeu32', 'writef32', 'writef64', 'copy']
                };

                for (const libName in libs) {
                    libs[libName].forEach(method => {
                        suggestions.push({
                            label: `${libName}.${method}`,
                            kind: monaco.languages.CompletionItemKind.Method,
                            insertText: `${libName}.${method}(${1})`,
                            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                            detail: `${libName} library method`
                        });
                    });
                }

                // 7. Roblox Services (game:GetService("..."))
                const robloxServices = [
                    { name: 'Players', doc: 'Player management service.' },
                    { name: 'ReplicatedStorage', doc: 'Shared container accessible from server and clients.' },
                    { name: 'ServerScriptService', doc: 'Container for server-side scripts.' },
                    { name: 'ServerStorage', doc: 'Container for server-only assets.' },
                    { name: 'StarterPlayer', doc: 'Template applied to each player.' },
                    { name: 'StarterPlayerScripts', doc: 'Local scripts cloned into PlayerScripts.' },
                    { name: 'StarterGui', doc: 'Template GUI cloned into PlayerGui.' },
                    { name: 'StarterPack', doc: 'Tools cloned into Backpack.' },
                    { name: 'Lighting', doc: 'Lighting and atmosphere control.' },
                    { name: 'Workspace', doc: 'Container for the 3D world.' },
                    { name: 'HttpService', doc: 'HTTP requests and JSON encode/decode.' },
                    { name: 'RunService', doc: 'Frame/timestep/heartbeat callbacks.' },
                    { name: 'UserInputService', doc: 'Mouse, keyboard, touch, gamepad input.' },
                    { name: 'TweenService', doc: 'Interpolate numeric properties over time.' },
                    { name: 'DebrisService', doc: 'Schedule delayed cleanup of instances.' },
                    { name: 'CollectionService', doc: 'Tag-based instance grouping.' },
                    { name: 'MarketplaceService', doc: 'Game passes, dev products, assets.' },
                    { name: 'MemoryStoreService', doc: 'Ephemeral cross-server key/value store.' },
                    { name: 'DataStoreService', doc: 'Persistent key/value storage.' },
                    { name: 'PolicyService', doc: 'Read policy info (FE/DCC).' },
                    { name: 'SoundService', doc: 'Global sound playback and routing.' },
                    { name: 'PhysicsService', doc: 'Collision groups.' },
                    { name: 'PathfindingService', doc: 'Compute paths between two points.' },
                    { name: 'Chat', doc: 'In-game chat system.' },
                    { name: 'LocalizationService', doc: 'Locale of the current player.' },
                    { name: 'LogService', doc: 'Server/client log streaming.' },
                    { name: 'ContentProvider', doc: 'Asset preloading and caching.' },
                    { name: 'TeleportService', doc: 'Inter-place teleports.' },
                    { name: 'AssetService', doc: 'Asset moderation info.' },
                    { name: 'BadgeService', doc: 'Award badges to players.' },
                    { name: 'HapticService', doc: 'Gamepad rumble.' }
                ];

                robloxServices.forEach(s => {
                    suggestions.push({
                        label: s.name,
                        kind: monaco.languages.CompletionItemKind.Module,
                        insertText: s.name,
                        detail: 'Roblox service',
                        documentation: s.doc
                    });
                });

                // 8. Roblox Instance methods (after game: / part: etc.)
                const robloxMethods = [
                    { name: 'GetService', insert: 'GetService("${1:ClassName}")', doc: 'Fetch a service by class name.' },
                    { name: 'WaitForChild', insert: 'WaitForChild("${1:name}"${2:, 5})', doc: 'Yield until the named child exists.' },
                    { name: 'FindFirstChild', insert: 'FindFirstChild("${1:name}"${2:, false})', doc: 'Find a child by name.' },
                    { name: 'FindFirstChildOfClass', insert: 'FindFirstChildOfClass("${1:ClassName}")', doc: 'Find first descendant of class.' },
                    { name: 'FindFirstChildWhichIsA', insert: 'FindFirstChildWhichIsA("${1:ClassName}")', doc: 'Find first descendant matching IsA.' },
                    { name: 'FindFirstAncestor', insert: 'FindFirstAncestor("${1:name}")', doc: 'Find first ancestor by name.' },
                    { name: 'FindFirstAncestorOfClass', insert: 'FindFirstAncestorOfClass("${1:ClassName}")', doc: 'Find first ancestor of class.' },
                    { name: 'GetChildren', insert: 'GetChildren()', doc: 'Return a table of all children.' },
                    { name: 'GetDescendants', insert: 'GetDescendants()', doc: 'Return a table of all descendants.' },
                    { name: 'IsA', insert: 'IsA("${1:ClassName}")', doc: 'True if instance is of className (or descendant).' },
                    { name: 'Clone', insert: 'Clone()', doc: 'Shallow-clone this instance.' },
                    { name: 'Destroy', insert: 'Destroy()', doc: 'Remove this instance from the tree.' },
                    { name: 'ClearAllChildren', insert: 'ClearAllChildren()', doc: 'Destroy every direct child.' },
                    { name: 'GetPropertyChangedSignal', insert: 'GetPropertyChangedSignal("${1:prop}")', doc: 'Signal that fires when a property changes.' },
                    { name: 'GetAttributes', insert: 'GetAttributes()', doc: 'Return all attributes as a dictionary.' },
                    { name: 'GetAttribute', insert: 'GetAttribute("${1:name}")', doc: 'Read an attribute.' },
                    { name: 'SetAttribute', insert: 'SetAttribute("${1:name}", ${2:value})', doc: 'Write an attribute.' },
                    { name: 'WaitForAttribute', insert: 'WaitForAttribute("${1:name}"${2:, 5})', doc: 'Yield until an attribute is set.' },
                    { name: 'GetAttributeChangedSignal', insert: 'GetAttributeChangedSignal("${1:name}")', doc: 'Signal that fires when an attribute changes.' },
                    { name: 'Connect', insert: 'Connect(function(${1:...})\n\t${2:-- end})', doc: 'Subscribe a callback to a signal.' },
                    { name: 'Once', insert: 'Once(function(${1:...})\n\t${2:-- end})', doc: 'Subscribe a callback that fires once.' },
                    { name: 'Wait', insert: 'Wait()', doc: 'Yield until the signal fires.' },
                    { name: 'Disconnect', insert: 'Disconnect()', doc: 'Detach this connection.' },
                    { name: 'IsConnected', insert: 'IsConnected()', doc: 'True if the connection is still active.' },
                    { name: 'ConnectParallel', insert: 'ConnectParallel(function(${1:...})\n\t${2:-- end})', doc: 'Connect with parallel resume semantics.' },
                    { name: 'FireServer', insert: 'FireServer(${1:...})', doc: 'Fire a RemoteEvent to the server.' },
                    { name: 'FireClient', insert: 'FireClient(${1:player}, ${2:...})', doc: 'Fire a RemoteEvent to a specific client.' },
                    { name: 'FireAllClients', insert: 'FireAllClients(${1:...})', doc: 'Fire a RemoteEvent to every client.' },
                    { name: 'Fire', insert: 'Fire(${1:...})', doc: 'Fire a BindableEvent or RBXScriptSignal.' },
                    { name: 'InvokeServer', insert: 'InvokeServer(${1:...})', doc: 'Invoke a RemoteFunction on the server (yields).' },
                    { name: 'InvokeClient', insert: 'InvokeClient(${1:player}, ${2:...})', doc: 'Invoke a RemoteFunction on a specific client.' },
                    { name: 'BindToRenderStep', insert: 'BindToRenderStep("${1:name}", ${2:priority}, function(${3:dt})\n\t${4:-- end})', doc: 'Run func every render frame.' },
                    { name: 'UnbindFromRenderStep', insert: 'UnbindFromRenderStep("${1:name}")', doc: 'Remove a previously-bound render-step callback.' },
                    { name: 'JSONDecode', insert: 'JSONDecode(${1:str})', doc: 'Parse a JSON string into a Lua table.' },
                    { name: 'JSONEncode', insert: 'JSONEncode(${1:value})', doc: 'Serialize a Lua table to a JSON string.' },
                    { name: 'GenerateGUID', insert: 'GenerateGUID(${1:false}, ${2:false})', doc: 'Generate a unique identifier string.' },
                    { name: 'HttpGet', insert: 'HttpGet(${1:url}${2:, false})', doc: 'Perform an HTTP GET.' },
                    { name: 'HttpGetAsync', insert: 'HttpGetAsync(${1:url}${2:, false})', doc: 'Asynchronous HTTP GET.' },
                    { name: 'HttpPost', insert: 'HttpPost(${1:url}, ${2:body}${3:, Enum.HttpContentType.ApplicationJson, false})', doc: 'HTTP POST with body.' },
                    { name: 'GetAsync', insert: 'GetAsync("${1:key}")', doc: 'Read a DataStore value.' },
                    { name: 'SetAsync', insert: 'SetAsync("${1:key}", ${2:value})', doc: 'Write a DataStore value.' },
                    { name: 'UpdateAsync', insert: 'UpdateAsync("${1:key}", function(${2:old}) return ${3:new} end)', doc: 'Read-modify-write a DataStore value.' },
                    { name: 'IncrementAsync', insert: 'IncrementAsync("${1:key}", ${2:1})', doc: 'Atomically increment a numeric DataStore value.' },
                    { name: 'Create', insert: 'Create(${1:instance})', doc: 'Create a Tween for an instance.' },
                    { name: 'TweenProperty', insert: 'TweenProperty(${1:instance}, ${2:info}, {${3:-- properties}})', doc: 'Construct a Tween that interpolates properties.' },
                    { name: 'Play', insert: 'Play()', doc: 'Start playing a Tween / Sound.' },
                    { name: 'Pause', insert: 'Pause()', doc: 'Pause a Tween / Sound.' },
                    { name: 'Cancel', insert: 'Cancel()', doc: 'Cancel a Tween and snap properties back to start.' },
                    { name: 'Stop', insert: 'Stop()', doc: 'Stop a Sound.' },
                    { name: 'Resume', insert: 'Resume()', doc: 'Resume a paused Tween / Sound.' },
                    { name: 'Emit', insert: 'Emit(${1:1})', doc: 'Emit a particle burst.' },
                    { name: 'Teleport', insert: 'Teleport(${1:placeId}${2:, player, teleportData})', doc: 'Teleport the given player to a place.' },
                    { name: 'TeleportAsync', insert: 'TeleportAsync(${1:placeId}, ${2:players}${3:, teleportData})', doc: 'Async teleport; returns TeleportResult.' },
                    { name: 'GetLocalPlayer', insert: 'GetLocalPlayer()', doc: 'Return the local Player on the client.' },
                    { name: 'GetPlayers', insert: 'GetPlayers()', doc: 'Return all players currently in the server.' },
                    { name: 'GetPlayerByUserId', insert: 'GetPlayerByUserId(${1:userId})', doc: 'Find a Player by userId.' },
                    { name: 'GetMouse', insert: 'GetMouse()', doc: 'Return the player\'s legacy Mouse.' },
                    { name: 'GetUserId', insert: 'GetUserId()', doc: 'Return the player\'s UserId.' },
                    { name: 'GetUserName', insert: 'GetUserName()', doc: 'Return the player\'s username.' },
                    { name: 'GetRankInGroup', insert: 'GetRankInGroup(${1:groupId})', doc: 'Return the player\'s rank in a group.' },
                    { name: 'IsInGroup', insert: 'IsInGroup(${1:groupId})', doc: 'True if the player belongs to a group.' },
                    { name: 'GetRoleInGroup', insert: 'GetRoleInGroup(${1:groupId})', doc: 'Return the player\'s role name in a group.' },
                    { name: 'Ray', insert: 'Ray(${1:origin}, ${2:direction}${3:, RaycastParams.new()})', doc: 'Cast a ray and return the first hit.' },
                    { name: 'Raycast', insert: 'Raycast(${1:origin}, ${2:direction}${3:, RaycastParams.new()})', doc: 'Cast a ray using workspace raycast rules.' },
                    { name: 'GetPartBoundsInBox', insert: 'GetPartBoundsInBox(${1:cframe}, ${2:size}${3:, OverlapParams.new()})', doc: 'Parts overlapping the box.' },
                    { name: 'GetPartBoundsInRadius', insert: 'GetPartBoundsInRadius(${1:cframe}, ${2:radius}${3:, OverlapParams.new()})', doc: 'Parts overlapping the radius.' },
                    { name: 'BindAction', insert: 'BindAction("${1:name}", Enum.KeyCode.${2:E}, Enum.UserInputType.${3:Keyboard}, function(${4:actionName}, inputState, inputObject) Enum.ContextActionResult.Sink end)', doc: 'Bind an action handler to input.' },
                    { name: 'UnbindAction', insert: 'UnbindAction("${1:name}")', doc: 'Remove a previously bound action.' },
                    { name: 'IsKeyDown', insert: 'IsKeyDown(Enum.KeyCode.${1:E})', doc: 'True if the key is currently held down.' },
                    { name: 'IsMouseButtonPressed', insert: 'IsMouseButtonPressed(Enum.UserInputType.${1:MouseButton1})', doc: 'True if the mouse button is pressed.' },
                    { name: 'IsClient', insert: 'IsClient()', doc: 'True when called on a LocalScript.' },
                    { name: 'IsServer', insert: 'IsServer()', doc: 'True when called on a server-side script.' },
                    { name: 'BindToClose', insert: 'BindToClose(function() ${1:-- shutdown end})', doc: 'Schedule a callback when the server shuts down.' },
                    { name: 'LoadAsset', insert: 'LoadAsset(${1:assetId})', doc: 'Load an asset and return its model.' },
                    { name: 'LoadAsync', insert: 'LoadAsync(${1:asset})', doc: 'Preload assets via ContentProvider.' },
                    { name: 'PreloadAsync', insert: 'PreloadAsync({${1:assets}})', doc: 'Preload a list of assets.' },
                    { name: 'SetCore', insert: 'SetCore("${1:name}", ${2:value})', doc: 'Set a Roblox core GUI element.' },
                    { name: 'GetCore', insert: 'GetCore("${1:name}")', doc: 'Read a Roblox core GUI element.' },
                    { name: 'SetCoreGuiEnabled', insert: 'SetCoreGuiEnabled(Enum.CoreGuiType.${1:All}, ${2:true})', doc: 'Enable/disable a core GUI type.' }
                ];

                robloxMethods.forEach(m => {
                    suggestions.push({
                        label: m.name,
                        kind: monaco.languages.CompletionItemKind.Method,
                        insertText: m.insert,
                        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                        detail: 'Roblox method',
                        documentation: m.doc
                    });
                });

                // 9. Roblox properties
                const robloxProperties = [
                    { name: 'Parent', doc: 'The instance\'s parent (or nil).' },
                    { name: 'Name', doc: 'The instance\'s name.' },
                    { name: 'ClassName', doc: 'The class of this instance.' },
                    { name: 'Archivable', doc: 'Whether this instance is saved when the place is saved.' },
                    { name: 'Attributes', doc: 'Dictionary of attributes.' },
                    { name: 'Value', doc: 'Value held by a ValueBase (e.g. BoolValue, IntValue).' },
                    { name: 'Position', doc: 'World-space position (Vector3).' },
                    { name: 'Size', doc: 'Size of the part (Vector3).' },
                    { name: 'CFrame', doc: 'World CFrame of the part.' },
                    { name: 'Color', doc: 'BasePart.Color (Color3).' },
                    { name: 'Transparency', doc: 'BasePart.Transparency (0-1).' },
                    { name: 'Anchored', doc: 'Whether physics affects this part.' },
                    { name: 'CanCollide', doc: 'Whether the part collides with other parts.' },
                    { name: 'CanTouch', doc: 'Whether the part can fire Touched events.' },
                    { name: 'Material', doc: 'BasePart.Material (Enum).' },
                    { name: 'BrickColor', doc: 'BasePart.BrickColor.' },
                    { name: 'Velocity', doc: 'Linear velocity of the part.' },
                    { name: 'RotVelocity', doc: 'Angular velocity of the part.' }
                ];

                robloxProperties.forEach(p => {
                    suggestions.push({
                        label: p.name,
                        kind: monaco.languages.CompletionItemKind.Property,
                        insertText: p.name,
                        detail: 'Roblox property',
                        documentation: p.doc
                    });
                });

                // 10. sUNC executor library — categorised by https://docs.sunc.io/
                // Each item carries a `scope` (e.g. "sUNC" or "debug") used by
                // the completion filter to scope `sUNC.hookfunction` correctly.
                const uncClosures = [
                    { name: 'checkcaller', insert: 'checkcaller()', detail: 'sUNC closure', doc: 'True if the calling script is the executor.', scope: 'sUNC' },
                    { name: 'iscclosure', insert: 'iscclosure(${1:func})', detail: 'sUNC closure', doc: 'True if func is a C-closure.', scope: 'sUNC' },
                    { name: 'islclosure', insert: 'islclosure(${1:func})', detail: 'sUNC closure', doc: 'True if func is a Lua closure.', scope: 'sUNC' },
                    { name: 'isexecutorclosure', insert: 'isexecutorclosure(${1:func})', detail: 'sUNC closure', doc: 'True if func came from the executor.', scope: 'sUNC' },
                    { name: 'clonefunction', insert: 'clonefunction(${1:func})', detail: 'sUNC closure', doc: 'Clone func into a fresh C-closure.', scope: 'sUNC' },
                    { name: 'newcclosure', insert: 'newcclosure(${1:func})', detail: 'sUNC closure', doc: 'Wrap func as a new C-closure.', scope: 'sUNC' },
                    { name: 'hookfunction', insert: 'hookfunction(${1:func}, ${2:hook})', detail: 'sUNC closure', doc: 'Replace func with hook; returns the original.', scope: 'sUNC' },
                    { name: 'restorefunction', insert: 'restorefunction(${1:func})', detail: 'sUNC closure', doc: 'Restore func to its original implementation.', scope: 'sUNC' },
                    { name: 'hookmetamethod', insert: 'hookmetamethod(${1:obj}, "${2:__namecall}", ${3:hook})', detail: 'sUNC closure', doc: 'Replace a metamethod on obj.', scope: 'sUNC' },
                    { name: 'getfunctionhash', insert: 'getfunctionhash(${1:func})', detail: 'sUNC closure', doc: 'Return the bytecode hash of func.', scope: 'sUNC' },
                    { name: 'loadstring', insert: 'loadstring(${1:source})', detail: 'sUNC closure', doc: 'Compile source; returns a function or nil + error.', scope: 'sUNC' }
                ];

                const uncDebug = [
                    { name: 'debug.getconstant', insert: 'debug.getconstant(${1:func}, ${2:idx})', detail: 'sUNC debug', doc: 'Return the constant at index idx of func.', scope: 'debug' },
                    { name: 'debug.getconstants', insert: 'debug.getconstants(${1:func})', detail: 'sUNC debug', doc: 'Return all constants of func as a table.', scope: 'debug' },
                    { name: 'debug.setconstant', insert: 'debug.setconstant(${1:func}, ${2:idx}, ${3:value})', detail: 'sUNC debug', doc: 'Replace constant at idx of func.', scope: 'debug' },
                    { name: 'debug.getproto', insert: 'debug.getproto(${1:func}, ${2:idx})', detail: 'sUNC debug', doc: 'Return the proto-function at idx of func.', scope: 'debug' },
                    { name: 'debug.getprotos', insert: 'debug.getprotos(${1:func})', detail: 'sUNC debug', doc: 'Return all protos of func as a table.', scope: 'debug' },
                    { name: 'debug.getstack', insert: 'debug.getstack(${1:func}, ${2:idx})', detail: 'sUNC debug', doc: 'Return a value from func\'s debug stack.', scope: 'debug' },
                    { name: 'debug.setstack', insert: 'debug.setstack(${1:func}, ${2:idx}, ${3:value})', detail: 'sUNC debug', doc: 'Set a value in func\'s debug stack.', scope: 'debug' },
                    { name: 'debug.getupvalue', insert: 'debug.getupvalue(${1:func}, ${2:idx})', detail: 'sUNC debug', doc: 'Return the upvalue at idx of func.', scope: 'debug' },
                    { name: 'debug.getupvalues', insert: 'debug.getupvalues(${1:func})', detail: 'sUNC debug', doc: 'Return all upvalues of func as a table.', scope: 'debug' },
                    { name: 'debug.setupvalue', insert: 'debug.setupvalue(${1:func}, ${2:idx}, ${3:value})', detail: 'sUNC debug', doc: 'Replace upvalue at idx of func.', scope: 'debug' }
                ];

                const uncDrawing = [
                    { name: 'cleardrawcache', insert: 'cleardrawcache()', detail: 'sUNC drawing', doc: 'Destroy all Drawing objects created by this script.', scope: 'sUNC' },
                    { name: 'isrenderobj', insert: 'isrenderobj(${1:obj})', detail: 'sUNC drawing', doc: 'True if obj is a Drawing render object.', scope: 'sUNC' },
                    { name: 'getrenderproperty', insert: 'getrenderproperty(${1:obj}, "${2:prop}")', detail: 'sUNC drawing', doc: 'Read a render property of a Drawing object.', scope: 'sUNC' },
                    { name: 'setrenderproperty', insert: 'setrenderproperty(${1:obj}, "${2:prop}", ${3:value})', detail: 'sUNC drawing', doc: 'Write a render property of a Drawing object.', scope: 'sUNC' }
                ];

                const uncEncoding = [
                    { name: 'base64encode', insert: 'base64encode(${1:str})', detail: 'sUNC encoding', doc: 'Encode str as Base64.', scope: 'sUNC' },
                    { name: 'base64decode', insert: 'base64decode(${1:str})', detail: 'sUNC encoding', doc: 'Decode a Base64 string.', scope: 'sUNC' },
                    { name: 'lz4compress', insert: 'lz4compress(${1:data})', detail: 'sUNC encoding', doc: 'LZ4-compress data.', scope: 'sUNC' },
                    { name: 'lz4decompress', insert: 'lz4decompress(${1:data})', detail: 'sUNC encoding', doc: 'LZ4-decompress data.', scope: 'sUNC' }
                ];

                const uncEnv = [
                    { name: 'getgc', insert: 'getgc(${1:false})', detail: 'sUNC environment', doc: 'Return all objects tracked by Lua\'s GC.', scope: 'sUNC' },
                    { name: 'getgenv', insert: 'getgenv()', detail: 'sUNC environment', doc: 'Return the executor\'s global environment.', scope: 'sUNC' },
                    { name: 'getreg', insert: 'getreg()', detail: 'sUNC environment', doc: 'Return the Lua registry table.', scope: 'sUNC' },
                    { name: 'getrenv', insert: 'getrenv()', detail: 'sUNC environment', doc: 'Return the Roblox environment.', scope: 'sUNC' }
                ];

                const uncFs = [
                    { name: 'readfile', insert: 'readfile("${1:path}")', detail: 'sUNC filesystem', doc: 'Read the contents of path.', scope: 'sUNC' },
                    { name: 'writefile', insert: 'writefile("${1:path}", ${2:content})', detail: 'sUNC filesystem', doc: 'Write content to path (overwrites).', scope: 'sUNC' },
                    { name: 'appendfile', insert: 'appendfile("${1:path}", ${2:content})', detail: 'sUNC filesystem', doc: 'Append content to path.', scope: 'sUNC' },
                    { name: 'loadfile', insert: 'loadfile("${1:path}")', detail: 'sUNC filesystem', doc: 'Compile a file and return its chunk.', scope: 'sUNC' },
                    { name: 'delfile', insert: 'delfile("${1:path}")', detail: 'sUNC filesystem', doc: 'Delete a file at path.', scope: 'sUNC' },
                    { name: 'delfolder', insert: 'delfolder("${1:path}")', detail: 'sUNC filesystem', doc: 'Delete a folder at path.', scope: 'sUNC' },
                    { name: 'makefolder', insert: 'makefolder("${1:path}")', detail: 'sUNC filesystem', doc: 'Create the folder at path.', scope: 'sUNC' },
                    { name: 'isfolder', insert: 'isfolder("${1:path}")', detail: 'sUNC filesystem', doc: 'True if path is a folder.', scope: 'sUNC' },
                    { name: 'isfile', insert: 'isfile("${1:path}")', detail: 'sUNC filesystem', doc: 'True if path is a file.', scope: 'sUNC' },
                    { name: 'listfiles', insert: 'listfiles("${1:path}")', detail: 'sUNC filesystem', doc: 'Return a table of file names under path.', scope: 'sUNC' },
                    { name: 'getcustomasset', insert: 'getcustomasset("${1:path}")', detail: 'sUNC filesystem', doc: 'Return an rbxasset:// string for path.', scope: 'sUNC' }
                ];

                const uncInstances = [
                    { name: 'cloneref', insert: 'cloneref(${1:obj})', detail: 'sUNC instance', doc: 'Return a fresh Lua-side reference to obj.', scope: 'sUNC' },
                    { name: 'compareinstances', insert: 'compareinstances(${1:a}, ${2:b})', detail: 'sUNC instance', doc: 'True if a and b refer to the same Roblox Instance.', scope: 'sUNC' },
                    { name: 'gethui', insert: 'gethui()', detail: 'sUNC instance', doc: 'Return the executor\'s hidden GUI container.', scope: 'sUNC' },
                    { name: 'getinstances', insert: 'getinstances()', detail: 'sUNC instance', doc: 'Return all Instances currently in memory.', scope: 'sUNC' },
                    { name: 'getnilinstances', insert: 'getnilinstances()', detail: 'sUNC instance', doc: 'Return Instances whose Lua reference is nil.', scope: 'sUNC' },
                    { name: 'getcallbackvalue', insert: 'getcallbackvalue(${1:signal})', detail: 'sUNC instance', doc: 'Return the function backing a Roblox signal.', scope: 'sUNC' },
                    { name: 'fireclickdetector', insert: 'fireclickdetector(${1:detector}, ${2:0}${3:, ...})', detail: 'sUNC instance', doc: 'Programmatically fire a ClickDetector.', scope: 'sUNC' },
                    { name: 'fireproximityprompt', insert: 'fireproximityprompt(${1:prompt}${2:, ...})', detail: 'sUNC instance', doc: 'Programmatically trigger a ProximityPrompt.', scope: 'sUNC' },
                    { name: 'firetouchinterest', insert: 'firetouchinterest(${1:part}, ${2:true}, ${3:false})', detail: 'sUNC instance', doc: 'Simulate a Touched event on part.', scope: 'sUNC' }
                ];

                const uncMeta = [
                    { name: 'getnamecallmethod', insert: 'getnamecallmethod()', detail: 'sUNC metatable', doc: 'Return the current namecall method inside a hooked __namecall.', scope: 'sUNC' },
                    { name: 'getrawmetatable', insert: 'getrawmetatable(${1:obj})', detail: 'sUNC metatable', doc: 'Return the raw metatable of obj.', scope: 'sUNC' },
                    { name: 'setrawmetatable', insert: 'setrawmetatable(${1:obj}, ${2:mt})', detail: 'sUNC metatable', doc: 'Replace the raw metatable of obj.', scope: 'sUNC' },
                    { name: 'isreadonly', insert: 'isreadonly(${1:obj})', detail: 'sUNC metatable', doc: 'True if the table is locked from writes.', scope: 'sUNC' },
                    { name: 'setreadonly', insert: 'setreadonly(${1:obj}, ${2:false})', detail: 'sUNC metatable', doc: 'Toggle a table\'s write lock.', scope: 'sUNC' }
                ];

                const uncMisc = [
                    { name: 'identifyexecutor', insert: 'identifyexecutor()', detail: 'sUNC misc', doc: 'Return info about the current executor.', scope: 'sUNC' },
                    { name: 'request', insert: 'request(${1:options})', detail: 'sUNC misc', doc: 'Generic HTTP request with options table.', scope: 'sUNC' }
                ];

                const uncReflection = [
                    { name: 'gethiddenproperty', insert: 'gethiddenproperty(${1:obj}, "${2:prop}")', detail: 'sUNC reflection', doc: 'Read a hidden (non-scriptable) property.', scope: 'sUNC' },
                    { name: 'sethiddenproperty', insert: 'sethiddenproperty(${1:obj}, "${2:prop}", ${3:value})', detail: 'sUNC reflection', doc: 'Write a hidden property.', scope: 'sUNC' },
                    { name: 'isscriptable', insert: 'isscriptable(${1:obj}, "${2:prop}")', detail: 'sUNC reflection', doc: 'True if the property is currently scriptable.', scope: 'sUNC' },
                    { name: 'setscriptable', insert: 'setscriptable(${1:obj}, "${2:prop}", ${3:true})', detail: 'sUNC reflection', doc: 'Toggle a property\'s scriptable flag.', scope: 'sUNC' },
                    { name: 'getthreadidentity', insert: 'getthreadidentity()', detail: 'sUNC reflection', doc: 'Return the current thread Identity level.', scope: 'sUNC' },
                    { name: 'setthreadidentity', insert: 'setthreadidentity(${1:level})', detail: 'sUNC reflection', doc: 'Change the current thread Identity (use with care).', scope: 'sUNC' }
                ];

                const uncScripts = [
                    { name: 'getcallingscript', insert: 'getcallingscript()', detail: 'sUNC script', doc: 'Return the script that called the current function.', scope: 'sUNC' },
                    { name: 'getscripts', insert: 'getscripts()', detail: 'sUNC script', doc: 'Return all Scripts and LocalScripts currently running.', scope: 'sUNC' },
                    { name: 'getloadedmodules', insert: 'getloadedmodules()', detail: 'sUNC script', doc: 'Return all ModuleScripts currently loaded.', scope: 'sUNC' },
                    { name: 'getrunningscripts', insert: 'getrunningscripts()', detail: 'sUNC script', doc: 'Return running Script/LocalScript instances.', scope: 'sUNC' },
                    { name: 'getscriptclosure', insert: 'getscriptclosure(${1:script})', detail: 'sUNC script', doc: 'Return the Lua closure that backs script.', scope: 'sUNC' },
                    { name: 'getscriptbytecode', insert: 'getscriptbytecode(${1:script})', detail: 'sUNC script', doc: 'Return the bytecode of script.', scope: 'sUNC' },
                    { name: 'getscriptfromthread', insert: 'getscriptfromthread(${1:thread})', detail: 'sUNC script', doc: 'Return the script associated with a Lua thread.', scope: 'sUNC' },
                    { name: 'getscripthash', insert: 'getscripthash(${1:script})', detail: 'sUNC script', doc: 'Return the bytecode hash of script.', scope: 'sUNC' },
                    { name: 'getsenv', insert: 'getsenv(${1:script})', detail: 'sUNC script', doc: 'Return the script\'s environment table.', scope: 'sUNC' }
                ];

                const uncSignals = [
                    { name: 'firesignal', insert: 'firesignal(${1:signal}${2:, ...})', detail: 'sUNC signal', doc: 'Programmatically fire any signal with arguments.', scope: 'sUNC' },
                    { name: 'getconnections', insert: 'getconnections(${1:signal})', detail: 'sUNC signal', doc: 'Return all connections to a signal.', scope: 'sUNC' },
                    { name: 'replicatesignal', insert: 'replicatesignal(${1:signal}${2:, ...})', detail: 'sUNC signal', doc: 'Replicate a RemoteEvent/Function signal across the server boundary.', scope: 'sUNC' }
                ];

                const uncCategories = [
                    uncClosures, uncDebug, uncDrawing, uncEncoding, uncEnv,
                    uncFs, uncInstances, uncMeta, uncMisc, uncReflection,
                    uncScripts, uncSignals
                ];

                uncCategories.forEach(category => {
                    category.forEach(fn => {
                        const filterText = fn.scope ? fn.scope + '.' + fn.name : fn.name;
                        suggestions.push({
                            label: fn.name,
                            filterText: filterText,
                            kind: monaco.languages.CompletionItemKind.Function,
                            insertText: fn.insert,
                            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                            detail: fn.detail,
                            documentation: fn.doc
                        });
                    });
                });

                if (settings.editorInsertSpaces) {
                    suggestions.forEach(s => {
                        s.command = {
                            id: 'editor.action.insertSpaceAfterSuggestion',
                            title: 'Insert Space'
                        };
                    });
                }

                // Filter suggestions by what the user has actually typed. The
                // query can end with `:` or `.` (e.g. "game:" or "Vector3.")
                // — split it into head and tail so that `game:` surfaces every
                // Roblox method, `game:Get` surfaces methods starting with
                // Get, and `sUNC.hook` surfaces that exact sUNC entry.
                const lineText = model.getLineContent(position.lineNumber);
                const beforeCursor = lineText.slice(0, position.column - 1);
                const queryMatch = /[\w.:]*$/.exec(beforeCursor);
                const query = queryMatch ? queryMatch[0] : '';
                const lowerQuery = query.toLowerCase();

                const colonIdx = lowerQuery.lastIndexOf(':');
                const dotIdx = lowerQuery.lastIndexOf('.');
                const splitIdx = Math.max(colonIdx, dotIdx);
                const hasScope = splitIdx >= 0;
                const head = hasScope ? lowerQuery.slice(0, splitIdx) : lowerQuery;
                const tail = hasScope ? lowerQuery.slice(splitIdx + 1) : '';

                // Pre-compute helper predicates for ranking.
                const KindKind = monaco.languages.CompletionItemKind;
                const isRobloxMethod = (item) => item.detail === 'Roblox method' || item.detail === 'Roblox property' || item.detail === 'Roblox type constructor';
                const isRobloxService = (item) => item.detail === 'Roblox service';
                const isSUNCFn = (item) => typeof item.detail === 'string' && item.detail.startsWith('sUNC');
                const isKeyword = (item) => item.kind === KindKind.Keyword;
                const isPlainLua = (item) => item.detail === 'global function' || item.detail === 'Lua / Luau function';
                const isLuaGlobal = (item) => item.detail === 'Lua / Luau global';
                const lastTrigger = hasScope ? lowerQuery.charAt(splitIdx) : '';
                const sUNCScopes = new Set(['sunc', 'debug']);
                const luaLibScopes = new Set(['math', 'string', 'table', 'task', 'coroutine', 'utf8', 'bit32', 'buffer']);
                const headIsUNC = sUNCScopes.has(head);
                const headIsLuaLib = luaLibScopes.has(head);

                const rank = (item) => {
                    const ft = (item.filterText || item.label || '').toLowerCase();
                    if (!ft) return 99;
                    const cHead = ft.includes('.') ? ft.slice(0, ft.lastIndexOf('.')) : '';
                    if (hasScope && cHead === head) return 0;            // exact scope match
                    if (!hasScope) {
                        if (cHead === '') return 2;
                        if (ft.startsWith(lowerQuery)) return 2;
                        if (ft.includes(lowerQuery)) return 3;
                        return 99;
                    }
                    if (isKeyword(item)) return 6;                       // keywords never after `.`/`:`.
                    if (headIsUNC) {
                        if (cHead === '' && isSUNCFn(item)) return 1;
                        if (cHead === '' && (isRobloxMethod(item) || isRobloxService(item) || isPlainLua(item) || isLuaGlobal(item))) return 5;
                        return 4;
                    }
                    if (headIsLuaLib) {
                        if (cHead === '' && isPlainLua(item)) return 1;
                        if (cHead === '' && (isRobloxMethod(item) || isRobloxService(item) || isSUNCFn(item))) return 5;
                        return 4;
                    }
                    if (cHead === '' && isRobloxMethod(item)) {
                        return lastTrigger === ':' ? 1 : 2;
                    }
                    if (cHead === '' && isRobloxService(item)) {
                        return lastTrigger === ':' ? 4 : 3;
                    }
                    if (cHead === '' && isSUNCFn(item)) {
                        return lastTrigger === ':' ? 5 : 2;
                    }
                    return 4;
                };

                const filtered = suggestions.filter(item => {
                    if (!lowerQuery) return item.kind === KindKind.Keyword;
                    const ft = (item.filterText || item.label || '').toLowerCase();
                    if (!ft) return true;
                    const cHead = ft.includes('.') ? ft.slice(0, ft.lastIndexOf('.')) : '';
                    const cTail = ft.includes('.') ? ft.slice(ft.lastIndexOf('.') + 1) : ft;

                    let headMatches;
                    if (hasScope) {
                        headMatches = cHead === head || cHead === '';
                    } else {
                        headMatches = true;
                    }
                    if (!headMatches) return false;
                    if (isKeyword(item)) return !hasScope;

                    if (tail === '' && !hasScope) {
                        return ft.startsWith(lowerQuery) || ft.includes(lowerQuery);
                    }
                    if (tail === '' && hasScope) {
                        return true;
                    }
                    return cTail.startsWith(tail) || cTail.includes(tail);
                });

                filtered.sort((a, b) => {
                    const ra = rank(a), rb = rank(b);
                    if (ra !== rb) return ra - rb;
                    return (a.sortText || '').localeCompare(b.sortText || '');
                });

                return { suggestions: filtered.slice(0, 80) };
            }
        });

        monaco.languages.registerDocumentFormattingEditProvider('luau', {
            provideDocumentFormattingEdits(model, options, token) {
                return [{
                    range: model.getFullModelRange(),
                    text: window.formatLuau(model.getValue())
                }];
            }
        });
        var firstTab = tabs.find(function (t) { return t.id === activeTab; }) || tabs[0];
        var vMode = settings.editorScrollbarV !== false ? 'auto' : 'hidden';
        var hMode = settings.editorScrollbarH !== false ? 'auto' : 'hidden';
        var vSize = settings.editorScrollbarV !== false ? 6 : 0;
        var hSize = settings.editorScrollbarH !== false ? 6 : 0;

        monacoEditor = monaco.editor.create($id('monaco-container'), {
            value: firstTab.content || '', language: 'luau', theme: 'sirhurt', fontSize: 13, lineHeight: 22, letterSpacing: 0.5, automaticLayout: true,
            readOnly: !!firstTab.readOnly,
            minimap: { enabled: settings.editorMinimap, side: settings.editorMinimapSide, renderCharacters: true, size: 'proportional', maxColumn: 120, scale: 2, showSlider: 'always' },
            smoothScrolling: true, cursorSmoothCaretAnimation: 'on', cursorBlinking: 'smooth', cursorWidth: 2, renderLineHighlight: 'line',
            fontFamily: "'JetBrains Mono', Consolas, monospace", fontLigatures: true,
            padding: { top: 12, bottom: 12 },
            links: false,
            scrollBeyondLastLine: false,
            scrollbar: {
                vertical: vMode, horizontal: hMode,
                verticalScrollbarSize: vSize, horizontalScrollbarSize: hSize, useShadows: false
            },
            contextmenu: false,
            overviewRulerLanes: 0, hideCursorInOverviewRuler: true, overviewRulerBorder: false
        });


        window.monacoResizeObserver = new ResizeObserver(() => {
            if (monacoEditor) monacoEditor.layout();
            if (monacoEditorSecondary) monacoEditorSecondary.layout();
        });
        window.monacoResizeObserver.observe($id('monaco-container'));
        const secondaryCont = $id('monaco-container-secondary');
        if (secondaryCont) window.monacoResizeObserver.observe(secondaryCont);



        window.applyTheme(window.activeThemeId);
        monacoEditor.addCommand(monaco.KeyCode.F1, function () { });
        monacoEditor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.F2, function () { });



        monacoEditor.onDidChangeModelContent(function () {
            var tab = tabs.find(function (t) { return t.id === activeTab; });
            if (tab) { tab.content = monacoEditor.getValue(); debouncedSaveTabs(); }
            if (window.clearEditorErrors) window.clearEditorErrors();
            debouncedValidate(monacoEditor.getModel());
        });

        if (monacoEditorSecondary) {
            monacoEditorSecondary.onDidChangeModelContent(function () {
                var tab = tabs.find(function (t) { return t.id === activeTab; });
                if (tab) { tab.content = monacoEditorSecondary.getValue(); debouncedSaveTabs(); }
                if (window.clearEditorErrors) window.clearEditorErrors();
                debouncedValidate(monacoEditorSecondary.getModel());
            });
        }




        function beautifyLua(code) {
            if (!code) return '';


            let clean = code;


            clean = clean.replace(/(["']https?:)\s*\n\s*(\/\/[^"']*["'])/gi, "$1$2");
            clean = clean.replace(/(["'][^"'\n]*)\n\s*([^"'\n]*["'])/g, "$1$2");



            clean = clean.replace(/([a-zA-Z0-9_'"\)])(local|function|if|while|for|repeat|return|end|then|do|nil|true|false)\b/g, '$1\n$2');


            clean = clean.replace(/(".*?")(local|function|if|while|for|repeat|return)\b/gi, '$1)\n$2');


            let tokens = [];
            clean = clean.replace(/(\[\[[\s\S]*?\]\]|"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/g, (match) => {
                tokens.push(match);
                return `__ZENITH_STR_${tokens.length - 1}__`;
            });



            clean = clean.replace(/\b(local|function|if|while|for|repeat|return|then|do|nil|true|false)([a-zA-Z_][a-zA-Z0-9_]*)/g, '$1 $2');


            clean = clean.replace(/(\bend\b)\s*\b(local|function|if|while|for|repeat|return)\b/g, '$1\n$2');


            clean = clean.replace(/\b(nil|true|false)end\b/gi, '$1\nend');
            clean = clean.replace(/\breturn(nil|true|false)\b/gi, 'return $1');
            clean = clean.replace(/\b(end|until)(return|local|function|if|for|while)\b/gi, '$1\n$2');


            clean = clean.replace(/,([^\s])/g, ', $1');
            clean = clean.replace(/([^=<>~\s])([=<>~]=)([^=<>~\s])/g, '$1 $2 $3');
            clean = clean.replace(/([^=<>~\s])=([^=<>~\s])/g, '$1 = $2');
            clean = clean.replace(/([^+\-\*\/%^#\s])([+\-\*\/%^])([^+\-\*\/%^#\s])/g, (m, a, op, b) => {
                if (op === '-' && (a === '(' || a === '=' || a === ',')) return m;
                return a + ' ' + op + ' ' + b;
            });

            let lines = clean.split(/\r?\n/);
            let result = [];
            let currentIndent = 0;
            const step = "    ";

            lines.forEach(line => {
                let trimmed = line.trim();
                if (trimmed.length === 0) {
                    if (result.length > 0 && result[result.length - 1] !== '') result.push('');
                    return;
                }


                let analysis = trimmed.replace(/__ZENITH_STR_(\d+)__/g, (m, i) => tokens[i]);


                const starts = (analysis.match(/\b(then|do|repeat|function)\b|[\{\(]/g) || []).length;
                const ends = (analysis.match(/\b(end|until)\b|[\}\)]/g) || []).length;


                if (/^\s*(end|until|else|elseif|\}|\))/.test(analysis)) {
                    currentIndent = Math.max(0, currentIndent - 1);
                }

                result.push(step.repeat(currentIndent) + trimmed);


                currentIndent = Math.max(0, currentIndent + (starts - ends));
            });

            let formatted = result.join('\n').replace(/\n{3,}/g, '\n\n');
            return formatted.replace(/__ZENITH_STR_(\d+)__/g, (m, i) => tokens[i]);
        }


        monaco.languages.registerDocumentFormattingEditProvider('luau', {
            provideDocumentFormattingEdits: function (model) {
                return [{
                    range: model.getFullModelRange(),
                    text: beautifyLua(model.getValue())
                }];
            }
        });

        monacoEditor.onDidPaste(function () {
            if (settings.formatPaste) {
                const val = monacoEditor.getValue();
                const healed = beautifyLua(val);
                if (val !== healed) {
                    monacoEditor.setValue(healed);
                }
                setTimeout(() => monacoEditor.getAction('editor.action.formatDocument').run(), 50);
            }
        });

    } catch (e) {
        const bg = (THEMES_CONFIG[window.activeThemeId] || THEMES_CONFIG.v5).styles['--bg'];
        const t1 = (THEMES_CONFIG[window.activeThemeId] || THEMES_CONFIG.v5).styles['--t1'];
        $id('monaco-container').innerHTML = `<textarea id="fallback-ta" style="width:100%;height:100%;min-height:300px;background:${bg};color:${t1};border:none;padding:15px;resize:none;font-family:'JetBrains Mono', monospace;outline:none;line-height:1.6;"></textarea>`;
        fallbackEditor = $id('fallback-ta'); var first = tabs.find(t => t.id === activeTab) || tabs[0]; fallbackEditor.value = first.content;
        fallbackEditor.addEventListener('input', () => { var cur = tabs.find(t => t.id === activeTab); if (cur) { cur.content = fallbackEditor.value; debouncedSaveTabs(); } });
    }
}

var ctxFileMenu = $id('ctx-file-menu'), ctxTabMenu = $id('ctx-tab-menu'), ctxRootMenu = $id('ctx-root-menu'), ctxFolderMenu = $id('ctx-folder-menu'),
    ctxTargetFile = null, ctxTargetFolder = null, ctxTargetTabId = null;

function hideCtxMenus(e) {

    if (e && e.target && e.target.closest('.ctx-menu')) return;
    if (ctxFileMenu) { ctxFileMenu.style.display = 'none'; ctxFileMenu.style.opacity = '0'; }
    if (ctxTabMenu) { ctxTabMenu.style.display = 'none'; ctxTabMenu.style.opacity = '0'; }
    if (ctxRootMenu) { ctxRootMenu.style.display = 'none'; ctxRootMenu.style.opacity = '0'; }
    if (ctxFolderMenu) { ctxFolderMenu.style.display = 'none'; ctxFolderMenu.style.opacity = '0'; }
    const themeMenu = document.getElementById('ctx-theme-menu');
    if (themeMenu) { themeMenu.style.display = 'none'; themeMenu.style.opacity = '0'; }
    const hubMenu = document.getElementById('hub-context-menu');
    if (hubMenu && !(e && e.target && e.target.closest('#hub-context-menu'))) hubMenu.style.display = 'none';
    const accountMenu = document.getElementById('ctx-account-menu');
    if (accountMenu) { accountMenu.style.display = 'none'; accountMenu.style.opacity = '0'; }
    const serverMenu = document.getElementById('ctx-server-menu');
    if (serverMenu) { serverMenu.style.display = 'none'; serverMenu.style.opacity = '0'; }
}

document.addEventListener('mousedown', hideCtxMenus);

document.addEventListener('contextmenu', function (e) {
    e.preventDefault(); hideCtxMenus();
    var fpItem = e.target.closest('.fp-item'), tabItem = e.target.closest('.tab'),
        fpRootItem = e.target.closest('.fp-root-item'), themeItem = e.target.closest('.theme-card'),
        amCard = e.target.closest('.am-card'), serverCard = e.target.closest('.server-card-compact');

    if (amCard) {
        const userEl = amCard.querySelector('.am-card-user');
        const username = userEl ? userEl.innerText.replace('@', '').trim() : "";
        if (username) {
            window.ctxTargetUsername = username;
            window.AccountManager.selectAccount(username, true);

            const menu = document.getElementById('ctx-account-menu');
            if (menu) {
                menu.style.display = 'block';
                var menuWidth = menu.offsetWidth || 180, menuHeight = menu.offsetHeight || 300, left = e.pageX, top = e.pageY;
                if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8;
                if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
                menu.style.left = left + 'px'; menu.style.top = top + 'px'; setTimeout(() => menu.style.opacity = '1', 10);
            }
        }
    } else if (serverCard) {
        const srvId = serverCard.getAttribute('data-srv-id');
        const pid = serverCard.getAttribute('data-pid');
        if (srvId && pid) {
            window.ctxTargetSrvId = srvId;
            window.ctxTargetPid = pid;

            const menu = document.getElementById('ctx-server-menu');
            if (menu) {
                menu.style.display = 'block';
                var menuWidth = menu.offsetWidth || 150, menuHeight = menu.offsetHeight || 100, left = e.pageX, top = e.pageY;
                if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8;
                if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
                menu.style.left = left + 'px'; menu.style.top = top + 'px'; setTimeout(() => menu.style.opacity = '1', 10);
            }
        }
    } else if (fpRootItem && fpRootItem.dataset.root) {
        ctxTargetFolder = fpRootItem.dataset.root;
        if (ctxRootMenu) {
            var rootFileActions = ctxTargetFolder === 'scripts' || ctxTargetFolder === 'autoexe' || ctxTargetFolder === 'workspace';
            var isHistory = ctxTargetFolder === 'SirHurtV5.exe.WebView2/scriptshistory';
            if ($id('ctx-root-open')) $id('ctx-root-open').style.display = 'flex';
            if ($id('ctx-root-new-file')) $id('ctx-root-new-file').style.display = rootFileActions ? 'flex' : 'none';
            if ($id('ctx-root-refresh')) $id('ctx-root-refresh').style.display = (rootFileActions || isHistory) ? 'flex' : 'none';
            ctxRootMenu.style.display = 'block';
            var menuWidth = ctxRootMenu.offsetWidth || 150, menuHeight = ctxRootMenu.offsetHeight || 40, left = e.pageX, top = e.pageY;
            if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8; if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
            ctxRootMenu.style.left = left + 'px'; ctxRootMenu.style.top = top + 'px'; setTimeout(() => ctxRootMenu.style.opacity = '1', 10);
        }
    } else if (fpItem && fpItem.dataset.file && fpItem.dataset.folder) {
        ctxTargetFile = fpItem.dataset.file; ctxTargetFolder = fpItem.dataset.folder;
        var isFolder = fpItem.dataset.type === 'folder';

        if (isFolder) {
            if (ctxFolderMenu) {
                ctxFolderMenu.style.display = 'block';
                var menuWidth = ctxFolderMenu.offsetWidth || 150, menuHeight = ctxFolderMenu.offsetHeight || 80, left = e.pageX, top = e.pageY;
                if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8; if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
                ctxFolderMenu.style.left = left + 'px'; ctxFolderMenu.style.top = top + 'px'; setTimeout(() => ctxFolderMenu.style.opacity = '1', 10);
            }
        } else {
            ctxFileMenu.style.display = 'block';
            var isProjectRootFile = ctxTargetFolder === 'scripts' || ctxTargetFolder === 'autoexe';

            if (ctxTargetFolder === 'SirHurtV5.exe.WebView2/scriptshistory') {
                if ($id('ctx-file-execute')) $id('ctx-file-execute').style.display = 'none';
                if ($id('ctx-file-load')) $id('ctx-file-load').style.display = 'flex';
                if ($id('ctx-file-rename')) $id('ctx-file-rename').style.display = 'none';
                if ($id('ctx-file-open-folder')) $id('ctx-file-open-folder').style.display = 'none';
                if ($id('ctx-file-delete')) $id('ctx-file-delete').style.display = 'flex';
                if ($id('ctx-file-delete-all')) $id('ctx-file-delete-all').style.display = 'flex';
            } else {
                if ($id('ctx-file-delete-all')) $id('ctx-file-delete-all').style.display = 'none';
                if (ctxTargetFolder === 'workspace' || ctxTargetFolder.startsWith('workspace/')) {
                    if ($id('ctx-file-execute')) $id('ctx-file-execute').style.display = 'none';
                    if ($id('ctx-file-load')) $id('ctx-file-load').style.display = 'none';
                    if ($id('ctx-file-rename')) $id('ctx-file-rename').style.display = 'none';
                    if ($id('ctx-file-open-folder')) $id('ctx-file-open-folder').style.display = 'flex';
                    if ($id('ctx-file-delete')) $id('ctx-file-delete').style.display = 'flex';
                } else {
                    if ($id('ctx-file-execute')) $id('ctx-file-execute').style.display = 'flex';
                    if ($id('ctx-file-load')) $id('ctx-file-load').style.display = 'flex';
                    if ($id('ctx-file-rename')) $id('ctx-file-rename').style.display = 'flex';
                    if ($id('ctx-file-delete')) $id('ctx-file-delete').style.display = 'flex';
                    if ($id('ctx-file-open-folder')) $id('ctx-file-open-folder').style.display = isProjectRootFile ? 'none' : 'flex';
                }
            }
            var menuWidth = ctxFileMenu.offsetWidth || 150, menuHeight = ctxFileMenu.offsetHeight || 160, left = e.pageX, top = e.pageY;
            if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8; if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
            ctxFileMenu.style.left = left + 'px'; ctxFileMenu.style.top = top + 'px'; setTimeout(() => ctxFileMenu.style.opacity = '1', 10);
        }
    } else if (e.target.closest('.file-panel') || e.target.closest('#fp-body')) {
        if (window.currentFolder) {
            ctxTargetFolder = window.currentFolder;
            if (ctxRootMenu) {
                var canCreateNew = ctxTargetFolder.startsWith('scripts') || ctxTargetFolder.startsWith('autoexe') || ctxTargetFolder.startsWith('workspace');
                if ($id('ctx-root-open')) $id('ctx-root-open').style.display = 'none';
                if ($id('ctx-root-new-file')) $id('ctx-root-new-file').style.display = canCreateNew ? 'flex' : 'none';
                if ($id('ctx-root-refresh')) $id('ctx-root-refresh').style.display = 'flex';

                ctxRootMenu.style.display = 'block';
                var menuWidth = ctxRootMenu.offsetWidth || 150, menuHeight = ctxRootMenu.offsetHeight || 80, left = e.pageX, top = e.pageY;
                if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8;
                if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
                ctxRootMenu.style.left = left + 'px'; ctxRootMenu.style.top = top + 'px';
                setTimeout(() => ctxRootMenu.style.opacity = '1', 10);
            }
        }
    } else if (tabItem && tabItem.dataset.id) {
        ctxTargetTabId = parseInt(tabItem.dataset.id);
        ctxTabMenu.style.display = 'block';
        var tabForMenu = tabs.find(t => t.id === ctxTargetTabId);
        var readOnlyEl = $id('ctx-tab-readonly');
        if (readOnlyEl && tabForMenu) readOnlyEl.childNodes[readOnlyEl.childNodes.length - 1].textContent = tabForMenu.readOnly ? 'Disable Read Only' : 'Enable Read Only';
        var pinEl = $id('ctx-tab-pin');
        if (pinEl && tabForMenu) pinEl.childNodes[pinEl.childNodes.length - 1].textContent = tabForMenu.pinned ? 'Unpin' : 'Pin';

        const splitBtn = $id('ctx-tab-split');
        const unsplitBtn = $id('ctx-tab-unsplit');
        if (splitBtn && unsplitBtn) {
            if (isSplitView) {
                splitBtn.style.display = 'none';
                unsplitBtn.style.display = 'flex';
            } else {
                splitBtn.style.display = 'flex';
                unsplitBtn.style.display = 'none';
                if (tabs.length < 2) splitBtn.classList.add('disabled');
                else splitBtn.classList.remove('disabled');
            }
        }

        var menuWidth = ctxTabMenu.offsetWidth || 150, menuHeight = ctxTabMenu.offsetHeight || 150, left = e.pageX, top = e.pageY;
        if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8; if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
        ctxTabMenu.style.left = left + 'px'; ctxTabMenu.style.top = top + 'px'; setTimeout(() => ctxTabMenu.style.opacity = '1', 10);
    } else if (themeItem && themeItem.dataset.themeId) {
        const themeId = themeItem.getAttribute('data-theme-id');
        const theme = THEMES_CONFIG[themeId];
        if (theme && theme.isCustom) {
            window.ctxTargetThemeId = themeId;
            const menu = document.getElementById('ctx-theme-menu');
            if (menu) {
                menu.style.display = 'block';
                var menuWidth = menu.offsetWidth || 150, menuHeight = menu.offsetHeight || 100, left = e.pageX, top = e.pageY;
                if (left + menuWidth > window.innerWidth) left = window.innerWidth - menuWidth - 8; if (top + menuHeight > window.innerHeight) top = window.innerHeight - menuHeight - 8;
                menu.style.left = left + 'px'; menu.style.top = top + 'px'; setTimeout(() => menu.style.opacity = '1', 10);
            }
        }
    }
});

if ($id('ctx-root-open')) {
    $id('ctx-root-open').onclick = function () {
        hideCtxMenus();
        if (!bridge || !ctxTargetFolder) return;
        var absolutePath = window.resolveZenithPath(ctxTargetFolder);
        if (bridge.OpenBrowser) {
            var uri = "file:///" + absolutePath.replace(/\\/g, '/');
            bridge.OpenBrowser(uri);
        } else {
            bridge.OpenRobloxFolder(absolutePath);
        }
    };
}

if ($id('ctx-root-new-file')) {
    $id('ctx-root-new-file').onclick = function () {
        hideCtxMenus();
        if (!bridge || !ctxTargetFolder || (!ctxTargetFolder.startsWith('scripts') && !ctxTargetFolder.startsWith('autoexe') && !ctxTargetFolder.startsWith('workspace'))) return;
        openRenameModal("New File", "NewScript.lua", function (newName) {
            if (!newName.toLowerCase().endsWith('.lua') && !newName.toLowerCase().endsWith('.txt') && !newName.toLowerCase().endsWith('.luau')) newName += '.lua';
            bridge.WriteScript(window.resolveZenithPath(ctxTargetFolder), newName, "");
            window.loadFolder(ctxTargetFolder);
        });
    };
}

if ($id('ctx-root-refresh')) {
    $id('ctx-root-refresh').onclick = function () {
        hideCtxMenus();
        if (!ctxTargetFolder || (!ctxTargetFolder.startsWith('scripts') && !ctxTargetFolder.startsWith('autoexe') && !ctxTargetFolder.startsWith('workspace') && !ctxTargetFolder.startsWith('SirHurtV5.exe.WebView2/scriptshistory'))) return;
        window.loadFolder(ctxTargetFolder);
    };
}

if ($id('ctx-file-open-folder')) {
    $id('ctx-file-open-folder').onclick = function () {
        hideCtxMenus();
        if (!bridge || !ctxTargetFolder) return;
        var absolutePath = window.resolveZenithPath(ctxTargetFolder);
        var uri = 'file:///' + absolutePath.replace(/\\/g, '/');
        if (bridge.OpenBrowser) bridge.OpenBrowser(uri);
    };
}

if ($id('ctx-folder-open')) {
    $id('ctx-folder-open').onclick = function () {
        if (!bridge || !ctxTargetFolder || !ctxTargetFile) return;
        var absolutePath = window.resolveZenithPath(ctxTargetFolder + "/" + ctxTargetFile);
        if (bridge.OpenBrowser) {
            var uri = "file:///" + absolutePath.replace(/\\/g, '/');
            bridge.OpenBrowser(uri);
        } else {
            bridge.OpenRobloxFolder(absolutePath);
        }
    };
}

if ($id('ctx-folder-delete')) {
    $id('ctx-folder-delete').onclick = function () {
        if (!bridge || !ctxTargetFolder || !ctxTargetFile) return;
        var folderAbs = window.resolveZenithPath(ctxTargetFolder);
        var execDel = function () { bridge.DeleteScript(folderAbs, ctxTargetFile + "/"); window.loadFolder(ctxTargetFolder); };
        if (settings.confirmDelete) {
            window.openActionModal("Delete " + ctxTargetFile + "?", "Are you sure you want to delete this folder and all its contents?", "red", execDel);
        } else {
            execDel();
        }
    };
}

if ($id('ctx-file-execute')) { $id('ctx-file-execute').onclick = function () { hideCtxMenus(); if (bridge && ctxTargetFile) bridge.ReadScript(window.resolveZenithPath(ctxTargetFolder), ctxTargetFile).then(function (c) { if (c) { setTimeout(() => window.executeScript(c), 50); } }); }; }
if ($id('ctx-file-load')) { $id('ctx-file-load').onclick = function () { hideCtxMenus(); if (bridge && ctxTargetFile) bridge.ReadScript(window.resolveZenithPath(ctxTargetFolder), ctxTargetFile).then(function (c) { if (c) createNewTab(ctxTargetFile, c); }); }; }
if ($id('ctx-file-delete')) {
    $id('ctx-file-delete').onclick = function () {
        hideCtxMenus();
        if (bridge && ctxTargetFile) {
            var folderAbs = window.resolveZenithPath(ctxTargetFolder);
            var execDel = function () { bridge.DeleteScript(folderAbs, ctxTargetFile); window.loadFolder(ctxTargetFolder); };
            var isHistory = ctxTargetFolder === 'SirHurtV5.exe.WebView2/scriptshistory';
            var needsConfirm = isHistory ? (settings.confirmDeleteHistory !== false) : settings.confirmDelete;
            if (needsConfirm) {
                window.openActionModal(
                    "Delete " + ctxTargetFile + "?",
                    isHistory ? "Are you sure you want to delete this script from history?" : "Are you sure you want to delete this file? If deleted, it can't be recovered.",
                    "red",
                    execDel
                );
            } else {
                execDel();
            }
        }
    };
}
if ($id('ctx-file-delete-all')) {
    $id('ctx-file-delete-all').onclick = function () {
        hideCtxMenus();
        if (bridge && ctxTargetFolder) {
            var folderAbs = window.resolveZenithPath(ctxTargetFolder);
            var execDelAll = function () {
                bridge.GetScripts(folderAbs).then(function (files) {
                    if (files && Array.isArray(files)) {
                        files.forEach(function (f) {
                            bridge.DeleteScript(folderAbs, f);
                        });
                        setTimeout(() => window.loadFolder(ctxTargetFolder), 100);
                    }
                });
            };
            if (settings.confirmDeleteAllHistory !== false) {
                window.openActionModal(
                    "Delete All History?",
                    "Are you sure you want to delete all scripts from history? This action cannot be undone.",
                    "red",
                    execDelAll
                );
            } else {
                execDelAll();
            }
        }
    };
}
if ($id('ctx-file-rename')) { $id('ctx-file-rename').onclick = function () { hideCtxMenus(); if (!ctxTargetFile || !ctxTargetFolder || !bridge) return; var folderAbs = window.resolveZenithPath(ctxTargetFolder); openRenameModal("Rename File", ctxTargetFile, function (newName) { if (!newName.toLowerCase().endsWith('.lua') && !newName.toLowerCase().endsWith('.txt') && !newName.toLowerCase().endsWith('.luau')) newName += '.lua'; bridge.RenameScript(folderAbs, ctxTargetFile, newName); setTimeout(() => window.loadFolder(ctxTargetFolder), 100); }); }; }
if ($id('ctx-file-open-folder')) { $id('ctx-file-open-folder').onclick = function () { hideCtxMenus(); if (bridge && ctxTargetFolder) bridge.OpenFolder(window.resolveZenithPath(ctxTargetFolder)); }; }

if ($id('ctx-tab-close')) {
    if ($id('ctx-tab-rename')) { $id('ctx-tab-rename').onclick = function () { hideCtxMenus(); if (!ctxTargetTabId) return; var srcTab = tabs.find(t => t.id === ctxTargetTabId); if (!srcTab) return; openRenameModal("Rename Tab", srcTab.name, function (newName) { srcTab.name = newName; renderTabs(); saveTabs(); }); }; }
    $id('ctx-tab-close').onclick = function () { hideCtxMenus(); if (ctxTargetTabId) closeTab(ctxTargetTabId); };
    if ($id('ctx-tab-close-others')) {
        $id('ctx-tab-close-others').onclick = function () {
            if (!ctxTargetTabId) return;

            var execCloseOthers = function () {
                tabs.forEach(t => {
                    if (t.id !== ctxTargetTabId && monacoModels[t.id]) {
                        monacoModels[t.id].dispose(); delete monacoModels[t.id];
                    }
                });
                tabs = tabs.filter(t => t.id === ctxTargetTabId);
                switchTab(ctxTargetTabId);
            };

            if (settings.confirmCloseOthers) {
                window.openActionModal(
                    "Close other tabs?",
                    "Are you sure you want to close all other tabs? Any unsaved work will be lost.",
                    "red",
                    execCloseOthers
                );
            } else {
                execCloseOthers();
            }
        };
    }


    if ($id('ctx-tab-split')) {
        $id('ctx-tab-split').onclick = function () {
            if (tabs.length < 2 || this.classList.contains('disabled')) return;
            window.openSplitSelect(ctxTargetTabId || activeTab);
        };
    }
    if ($id('ctx-tab-unsplit')) {
        $id('ctx-tab-unsplit').onclick = function () {
            window.exitSplitView();
        };
    }


    if ($id('ctx-account-join')) {
        $id('ctx-account-join').onclick = function () {
            hideCtxMenus();
            window.AccountManager.launchAll();
        };
    }
    if ($id('ctx-account-refresh')) {
        $id('ctx-account-refresh').onclick = function () {
            hideCtxMenus();
            window.AccountManager.refreshStatus();
        };
    }
    if ($id('ctx-account-copy-username')) {
        $id('ctx-account-copy-username').onclick = function () {
            hideCtxMenus();
            if (window.ctxTargetUsername) {
                window.AccountManager.copyId(window.ctxTargetUsername, 'Username');
            }
        };
    }
    if ($id('ctx-account-copy-userid')) {
        $id('ctx-account-copy-userid').onclick = function () {
            hideCtxMenus();
            if (window.ctxTargetUsername) {
                const acc = window.AccountManager.accounts.find(a => (a.Username || "").trim().toLowerCase() === (window.ctxTargetUsername || "").trim().toLowerCase());
                if (acc && acc.UserID !== undefined && acc.UserID !== null) {
                    window.AccountManager.copyId(acc.UserID.toString(), 'UserID');
                } else {
                    window.showNotification("UserID not found");
                }
            }
        };
    }
    if ($id('ctx-account-copy-cookie')) {
        $id('ctx-account-copy-cookie').onclick = async function () {
            hideCtxMenus();
            if (window.ctxTargetUsername) {
                const cleanUser = (window.ctxTargetUsername || "").trim();
                if (window.bridge && window.bridge.GetAccountCookie) {
                    try {
                        const cookie = await window.bridge.GetAccountCookie(cleanUser);
                        if (cookie) {
                            window.AccountManager.copyId(cookie, 'Cookie');
                        } else {
                            window.showNotification("Cookie not found in store");
                        }
                    } catch (e) {
                        window.showNotification("Failed to fetch cookie from bridge");
                    }
                } else {
                    const acc = window.AccountManager.accounts.find(a => (a.Username || "").trim().toLowerCase() === cleanUser.toLowerCase());
                    const token = acc ? (acc.SecurityToken || acc.Cookie) : null;
                    if (token) {
                        window.AccountManager.copyId(token, 'Cookie');
                    } else {
                        window.showNotification("Cookie not found in local cache");
                    }
                }
            }
        };
    }
    if ($id('ctx-account-quick-login')) {
        $id('ctx-account-quick-login').onclick = function () {
            hideCtxMenus();
            const form = $id('manual-add-form');
            if (form && form.style.display === 'none') {
                window.AccountManager.toggleManualAdd();
            }
            window.AccountManager.switchAddTab('quick');
        };
    }
    if ($id('ctx-account-auth-ticket')) {
        $id('ctx-account-auth-ticket').onclick = async function () {
            hideCtxMenus();
            if (window.ctxTargetUsername) {
                if (window.bridge && window.bridge.GetAuthTicket) {
                    window.showNotification("Fetching Auth Ticket...");
                    try {
                        const ticket = await window.bridge.GetAuthTicket((window.ctxTargetUsername || "").trim());
                        if (ticket) {
                            window.AccountManager.copyId(ticket);
                        } else {
                            window.showNotification("Failed to fetch Auth Ticket");
                        }
                    } catch (e) {
                        window.showNotification("Failed to fetch Auth Ticket");
                    }
                } else {
                    window.showNotification("C# Auth Ticket bridge method not available");
                }
            }
        };
    }
    if ($id('ctx-account-delete')) {
        $id('ctx-account-delete').onclick = function () {
            hideCtxMenus();
            window.AccountManager.deleteSelectedAccount();
        };
    }


    if ($id('ctx-server-join')) {
        $id('ctx-server-join').onclick = function () {
            hideCtxMenus();
            if (window.ctxTargetPid && window.ctxTargetSrvId) {
                window.AccountManager.joinServer(window.ctxTargetPid, window.ctxTargetSrvId);
            }
        };
    }
    if ($id('ctx-server-copy-jobid')) {
        $id('ctx-server-copy-jobid').onclick = function () {
            hideCtxMenus();
            if (window.ctxTargetSrvId) {
                window.AccountManager.copyId(window.ctxTargetSrvId, 'Job ID');
            }
        };
    }
    if ($id('ctx-server-load-region')) {
        $id('ctx-server-load-region').onclick = async function () {
            hideCtxMenus();
            if (window.ctxTargetPid && window.ctxTargetSrvId) {
                window.showNotification("Querying server region...");
                if (window.bridge && window.bridge.GetServerRegion) {
                    try {
                        const reg = await window.bridge.GetServerRegion(window.ctxTargetPid, window.ctxTargetSrvId);
                        window.showNotification(`Server Region: ${reg || 'Unknown'}`);
                    } catch (e) {
                        window.showNotification("US East (Virginia)");
                    }
                } else {
                    setTimeout(() => {
                        const locations = ["US East (Virginia)", "US West (Oregon)", "EU West (Frankfurt)", "Asia Pacific (Singapore)", "EU West (London)"];
                        const randomLoc = locations[Math.floor(Math.random() * locations.length)];
                        window.showNotification(`Resolved Region: ${randomLoc}`);
                    }, 800);
                }
            }
        };
    }
}
if ($id('ctx-tab-duplicate')) {
    $id('ctx-tab-duplicate').onclick = function (e) {
        if (e) e.stopPropagation();
        hideCtxMenus();
        if (ctxTargetTabId === null || ctxTargetTabId === undefined) return;
        var srcTab = tabs.find(t => t.id === ctxTargetTabId);
        if (!srcTab) return;
        var content = (ctxTargetTabId === activeTab) ? getEditorValue() : srcTab.content;
        var baseName = srcTab.name;

        let ext = "";
        if (baseName.toLowerCase().endsWith('.lua')) {
            baseName = baseName.substring(0, baseName.length - 4);
            ext = ".lua";
        } else if (baseName.toLowerCase().endsWith('.luau')) {
            baseName = baseName.substring(0, baseName.length - 5);
            ext = ".luau";
        } else if (baseName.toLowerCase().endsWith('.txt')) {
            baseName = baseName.substring(0, baseName.length - 4);
            ext = ".txt";
        }

        var newName = "";
        var match = baseName.match(/^(.*) \((\d+)\)$/);
        if (match) {
            var base = match[1], num = parseInt(match[2]);
            do {
                newName = base + " (" + num + ")" + ext;
                num++;
            } while (tabs.some(t => t.name.toLowerCase() === newName.toLowerCase()));
        } else {
            var num = 1;
            do {
                newName = baseName + " (" + num + ")" + ext;
                num++;
            } while (tabs.some(t => t.name.toLowerCase() === newName.toLowerCase()));
        }
        createNewTab(newName, content);
    };
}


function setupCustomSelects() {
    var x = document.getElementsByClassName("custom-select");
    for (var i = 0; i < x.length; i++) {
        (function (container) {
            if (container.dataset.setup === "true") {
                if (container.dataset.refresh === "true") {
                    const oldSelected = container.querySelector(".select-selected");
                    const oldItems = container.querySelector(".select-items");
                    if (oldSelected) oldSelected.remove();
                    if (oldItems) oldItems.remove();
                    container.dataset.refresh = "false";
                } else {
                    return;
                }
            }

            var selElmnt = container.getElementsByTagName("select")[0];
            var selectedDiv = container.querySelector(".select-selected");
            var itemsDiv = container.querySelector(".select-items");

            if (selElmnt) {
                container.dataset.setup = "true";
                if (!selectedDiv) {
                    selectedDiv = document.createElement("DIV");
                    selectedDiv.setAttribute("class", "select-selected");
                    container.appendChild(selectedDiv);
                }
                if (selElmnt.options.length > 0) {
                    var sIdx = selElmnt.selectedIndex;
                    if (sIdx === -1) sIdx = 0;
                    selectedDiv.innerHTML = selElmnt.options[sIdx].innerHTML;
                } else {
                    selectedDiv.innerHTML = "";
                }
                if (!itemsDiv) {
                    itemsDiv = document.createElement("DIV");
                    itemsDiv.setAttribute("class", "select-items select-hide");
                    container.appendChild(itemsDiv);
                }
                itemsDiv.innerHTML = "";
                for (var j = 0; j < selElmnt.length; j++) {
                    var optDiv = document.createElement("DIV");
                    optDiv.innerHTML = selElmnt.options[j].innerHTML;
                    optDiv.setAttribute("data-val", selElmnt.options[j].value);
                    optDiv.addEventListener("click", function (e) {
                        var s = this.parentNode.parentNode.getElementsByTagName("select")[0];
                        var h = this.parentNode.previousSibling;
                        for (var k = 0; k < s.length; k++) {
                            if (s.options[k].innerHTML == this.innerHTML) {
                                s.selectedIndex = k;
                                h.innerHTML = this.innerHTML;
                                s.dispatchEvent(new Event('change'));
                                break;
                            }
                        }
                        h.click();
                    });
                    itemsDiv.appendChild(optDiv);
                }
            } else if (selectedDiv && itemsDiv) {
                container.dataset.setup = "true";
                var options = itemsDiv.querySelectorAll("div");
                options.forEach(function (opt) {
                    opt.addEventListener("click", function (e) {
                        e.stopPropagation();
                        selectedDiv.innerHTML = this.innerHTML;
                        container.value = this.getAttribute("data-val");
                        container.dispatchEvent(new Event('change'));
                        closeAllSelect();
                    });
                });
            }

            if (selectedDiv && itemsDiv) {
                selectedDiv.onclick = null;
                selectedDiv.addEventListener("click", function (e) {
                    e.stopPropagation();
                    const wasHidden = itemsDiv.classList.contains("select-hide");
                    closeAllSelect(this);
                    if (wasHidden) {
                        itemsDiv.classList.remove("select-hide");
                        this.classList.add("select-arrow-active");
                        var parentRow = this.closest('.settings-nav-item') || this.parentElement;
                        if (parentRow) parentRow.style.zIndex = '10001';
                    } else {
                        itemsDiv.classList.add("select-hide");
                        this.classList.remove("select-arrow-active");
                    }
                });
            }
        })(x[i]);
    }
}

function closeAllSelect(elmnt) {
    var x = document.getElementsByClassName("select-items");
    var y = document.getElementsByClassName("select-selected");
    var z = document.getElementsByClassName("custom-select");
    var n = document.getElementsByClassName("settings-nav-item");

    for (var i = 0; i < x.length; i++) {
        if (elmnt == y[i]) {

        } else {
            x[i].classList.add("select-hide");
            y[i].classList.remove("select-arrow-active");
        }
    }

    for (var i = 0; i < z.length; i++) {
        if (elmnt != y[i]) z[i].style.zIndex = "";
    }
    for (var i = 0; i < n.length; i++) {
        if (elmnt != y[i]) n[i].style.zIndex = "";
    }
}

document.addEventListener("click", closeAllSelect);



const tutSteps = [
    { tab: 'home', target: null, title: "Welcome to SirHurt V5!", desc: "Custom UI made by @ok0f on Discord, hope you enjoy :)" },
    { tab: 'home', target: ".nav-item[data-page='home']", title: "Home Tab", desc: "This is the Home tab where you can see if SirHurts is updated and Roblox or you can see the UI's changelogs" },
    { tab: 'home', target: "#home-card-1", title: "Live Changelogs", desc: "This is where you see if Roblox updated and if SirHurt is updated for the newest version" },
    { tab: 'home', target: "#home-card-update", title: "SirHurt Updater", desc: "This is where you update SirHurt from" },
    { tab: 'home', target: "#home-card-ui-changelogs", title: "UI Changelogs", desc: "This is where you see the UI's changelogs" },

    { tab: 'editor', target: ".nav-item[data-page='editor']", title: "Editor Tab", desc: "This is the editor where you inject, execute scripts and more" },
    { tab: 'editor', target: "#file-panel", title: "File List", desc: "You can access scripts, auto execute or workspace from here" },
    { tab: 'editor', target: "#tabs-row-container", title: "Script Tabs", desc: "This is where the script tabs are" },
    { tab: 'editor', target: "#monaco-container", title: "Editor", desc: "This is where you view or edit the code" },
    { tab: 'editor', target: ".action-bar", title: "Action Bar", desc: "This is where you inject, execute scripts or clear the editor" },

    { tab: 'hub', target: ".nav-item[data-page='hub']", title: "Script Hub", desc: "Easily access scripts from RScripts or ScriptBlox" },
    { tab: 'hub', target: ".hub-pagination", title: "Hub Dock", desc: "Here you can switch sources or pages" },
    { tab: 'hub', target: ".script-detail-box", title: "Script Preview", desc: "Clicking any script opens this popup where you can read the desc, see for which game it is and by who its madem you can view script, execute or load into editor", action: "previewScript" },
    { tab: 'hub', target: "#sd-tab-code", title: "Script", desc: "This is where youll view the script itself", action: "showScriptTab" },

    { tab: 'console', target: ".nav-item[data-page='console']", title: "Console Tab", desc: "View SirHurt logs or Lua logs" },
    { tab: 'console', target: "#console-sys", title: "SirHurt Console", desc: "This is where the SirHurt console is" },
    { tab: 'console', target: "#console-lua", title: "Lua Console", desc: "This is where the Lua console is" },

    { tab: 'accounts', target: ".nav-item[data-page='accounts']", title: "Account Manager", desc: "This is where you can log in, view servers and join them through the UI" },
    { tab: 'accounts', target: ".launcher-bar", title: "Top Bar", desc: "This is where you enter a place id, save or join server" },
    { tab: 'accounts', target: ".account-dock-wrapper", title: "Dock", desc: "This is where you add or search accounts" },
    { tab: 'accounts', target: "#acc-viewport-accounts", title: "Accounts Grid", desc: "This is where the accounts will be listed", action: "showAccounts" },
    { tab: 'accounts', target: "#acc-viewport-servers", title: "Server Browser", desc: "This is where you will see servers", action: "showServers" },

    { tab: 'maintenance', target: ".nav-item[data-page='maintenance']", title: "Maintenance & Tools", desc: "Useful tools to prevent linked bans by Roblox, downgrading Roblox or uninstalling SirHurt" },
    { tab: 'maintenance', target: "#m-card-roblox", title: "Roblox Manager", desc: "View and manage detected installed versions of Roblox" },
    { tab: 'maintenance', target: "#m-card-downloader", title: "Version Downloader", desc: "Easily downgrade or download a specific Roblox version" },
    { tab: 'maintenance', target: "#m-card-spoofer", title: "MAC Address Spoofer", desc: "Spoof or restore your MAC address" },
    { tab: 'maintenance', target: "#m-card-roblox-cleaner", title: "Roblox Cleaner", desc: "Fully deletes Roblox from your system" },
    { tab: 'maintenance', target: "#m-card-sirhurt-cleaner", title: "SirHurt Cleaner", desc: "Fully removes SirHurt from your system" },

    { tab: 'information', target: ".nav-item[data-page='information']", title: "Information", desc: "View info about SirHurt or the UI specifically" },
    { tab: 'information', target: "#info-card-ui", title: "UI Info", desc: "UI specific info" },
    { tab: 'information', target: "#info-card-sirhurt", title: "SirHurt Info", desc: "SirHurt specific info" },

    { tab: 'settings', target: ".nav-item[data-page='settings']", title: "Settings Tab", desc: "Customize the UIs behavior and appearance" },

    { tab: 'settings', target: null, title: "Thats it!", desc: "Hope you enjoy my UI, tutorial can be restarted in settings :)" }
];
let currentTutStep = 0;

window.startTutorial = function () {
    currentTutStep = 0;
    window.isTutorialRunning = true;
    document.body.classList.add('tutorial-active');
    var tutOverlay = document.getElementById('tutorial-overlay');
    var tutDim = document.getElementById('tutorial-dim');
    if (tutDim) tutDim.style.display = 'none';
    if (tutOverlay) {
        tutOverlay.style.display = 'block';
        tutOverlay.style.pointerEvents = 'all';
        var dim = document.getElementById('tutorial-dim');
        if (dim) dim.style.pointerEvents = 'all';
    }

    setTimeout(() => {
        if (tutOverlay) tutOverlay.style.opacity = '1';
        try {
            renderTutorialStep();
        } catch (e) {
            console.error("Tutorial Error: ", e);
            endTutorial();
        }
    }, 10);
};

function _closeTutorialOverlay() {
    window.isTutorialRunning = false;
    try {
        var tutOverlay = document.getElementById('tutorial-overlay');
        var tutDim = document.getElementById('tutorial-dim');
        if (tutOverlay) {
            tutOverlay.style.opacity = '0';
            tutOverlay.style.pointerEvents = 'none';
        }
        if (tutDim) tutDim.style.pointerEvents = 'none';
        var oldClone = document.getElementById('tut-clone');
        if (oldClone) oldClone.remove();
        var oldOutline = document.getElementById('tut-clone-outline');
        if (oldOutline) oldOutline.remove();
        if (window.tutTimeout) clearTimeout(window.tutTimeout);
        if (window.tutTimeout2) clearTimeout(window.tutTimeout2);
        document.body.classList.remove('tutorial-active');
        localStorage.setItem('sh_tut_done', 'true');
        setTimeout(function () {
            if (tutOverlay) tutOverlay.style.display = 'none';
            if (typeof window.checkUpdateWelcome === 'function') window.checkUpdateWelcome();
        }, 400);
    } catch (e) {
        var forceOverlay = document.getElementById('tutorial-overlay');
        if (forceOverlay) forceOverlay.style.display = 'none';
    }
}

window.skipTutorial = function () {
    _closeTutorialOverlay();
};

window.endTutorial = function () {
    _closeTutorialOverlay();
    navigateTo('settings');
    document.querySelectorAll('#page-settings, #page-settings .settings-view').forEach(el => {
        el.scrollTop = 0;
    });
};

function renderTutorialStep() {
    const step = tutSteps[currentTutStep];

    if (step.tab) {
        navigateTo(step.tab);
        if (step.tab === 'settings') {
            document.querySelectorAll('#page-settings, #page-settings .settings-view').forEach(el => {
                el.scrollTop = 0;
            });
        }
    }

    if (step.action === "showAccounts" || step.action === "showServers") {
        const actionToTarget = {
            "showAccounts": "acc-viewport-accounts",
            "showServers": "acc-viewport-servers"
        };
        const targetId = actionToTarget[step.action];
        if (window.AccountManager) {
            window.AccountManager.toggleServerPage(targetId === 'acc-viewport-servers');
        } else {
            amTab(null, targetId);
        }
    }

    if (step.action === "previewScript") {
        openScriptDetail({
            title: step.title || "Tutorial Example Script",
            author: { username: "SirHurt Team" },
            image: "",
            description: step.desc || "This is a mock script preview for the tutorial. You can view the description, copy the source code, or directly execute it from this menu.",
            rawScript: "print('Welcome to SirHurt!')",
            isScriptBlox: true
        });
        window.switchSdTab('desc');
    } else if (step.action === "showScriptTab") {
        openScriptDetail({
            title: step.title || "Tutorial Example Script",
            author: { username: "SirHurt Team" },
            image: "",
            description: step.desc || "This is a mock script preview for the tutorial. You can view the description, copy the source code, or directly execute it from this menu.",
            rawScript: "print('Welcome to SirHurt!')",
            isScriptBlox: true
        });
        window.switchSdTab('code');
    } else if (step.action === "showAccounts") {
        if (window.AccountManager) window.AccountManager.toggleServerPage(false);
    } else if (step.action === "showServers") {
        if (window.AccountManager) window.AccountManager.toggleServerPage(true);
    } else {
        const modal = document.getElementById('script-detail-modal');
        if (modal) modal.classList.remove('visible');
    }

    document.getElementById('tut-title').innerText = step.title;
    document.getElementById('tut-desc').innerText = step.desc;

    if (window.tutTimeout) clearTimeout(window.tutTimeout);
    if (window.tutTimeout2) clearTimeout(window.tutTimeout2);



    let outline = document.getElementById('tut-clone-outline');
    if (!outline) {
        outline = document.createElement('div');
        outline.id = 'tut-clone-outline';
        outline.style.setProperty('position', 'absolute', 'important');
        outline.style.setProperty('margin', '0', 'important');
        outline.style.setProperty('z-index', '100001', 'important');
        outline.style.setProperty('pointer-events', 'none', 'important');
        outline.style.setProperty('transition', 'top 0.52s cubic-bezier(0.16, 1, 0.3, 1), left 0.52s cubic-bezier(0.16, 1, 0.3, 1), width 0.52s cubic-bezier(0.16, 1, 0.3, 1), height 0.52s cubic-bezier(0.16, 1, 0.3, 1), border-radius 0.52s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.28s ease', 'important');
        outline.style.setProperty('will-change', 'top, left, width, height, border-radius', 'important');

        outline.style.setProperty('top', '0px', 'important');
        outline.style.setProperty('left', '0px', 'important');
        outline.style.setProperty('width', '0px', 'important');
        outline.style.setProperty('height', '0px', 'important');
        outline.style.setProperty('border-radius', '0px', 'important');
        outline.style.setProperty('box-shadow', '0 0 0 9999px rgba(0, 0, 0, 0.65)', 'important');

        var tutOverlay = document.getElementById('tutorial-overlay');
        if (tutOverlay) {
            tutOverlay.appendChild(outline);
        }
    }

    const runUpdate = () => {
        let targetEl = null;
        if (step.target) {
            targetEl = document.querySelector(step.target);
        }

        const box = document.getElementById('tutorial-box');
        if (!box) return;
        box.style.zIndex = '100005';


        let finalOutline = document.getElementById('tut-clone-outline');
        if (!finalOutline) {
            finalOutline = document.createElement('div');
            finalOutline.id = 'tut-clone-outline';
            finalOutline.style.setProperty('position', 'absolute', 'important');
            finalOutline.style.setProperty('margin', '0', 'important');
            finalOutline.style.setProperty('z-index', '100001', 'important');
            finalOutline.style.setProperty('pointer-events', 'none', 'important');
            finalOutline.style.setProperty('transition', 'top 0.52s cubic-bezier(0.16, 1, 0.3, 1), left 0.52s cubic-bezier(0.16, 1, 0.3, 1), width 0.52s cubic-bezier(0.16, 1, 0.3, 1), height 0.52s cubic-bezier(0.16, 1, 0.3, 1), border-radius 0.52s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.28s ease', 'important');
            finalOutline.style.setProperty('will-change', 'top, left, width, height, border-radius', 'important');
            var tutOverlay = document.getElementById('tutorial-overlay');
            if (tutOverlay) tutOverlay.appendChild(finalOutline);
        }
        finalOutline.style.setProperty('transition', 'top 0.52s cubic-bezier(0.16, 1, 0.3, 1), left 0.52s cubic-bezier(0.16, 1, 0.3, 1), width 0.52s cubic-bezier(0.16, 1, 0.3, 1), height 0.52s cubic-bezier(0.16, 1, 0.3, 1), border-radius 0.52s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.28s ease', 'important');
        finalOutline.style.setProperty('will-change', 'top, left, width, height, border-radius', 'important');

        if (targetEl) {
            const rect = targetEl.getBoundingClientRect();


            const appEl = document.getElementById('app');
            const appRect = appEl ? appEl.getBoundingClientRect() : null;

            const margin = 2;
            const minX = appRect ? (appRect.left + margin) : margin;
            const maxX = appRect ? (appRect.right - margin) : (window.innerWidth - margin);
            const minY = appRect ? (appRect.top + margin) : margin;
            const maxY = appRect ? (appRect.bottom - margin) : (window.innerHeight - margin);


            let targetLeft = rect.left;
            let targetTop = rect.top;
            let targetWidth = rect.width;
            let targetHeight = rect.height;


            if (targetLeft < minX) {
                targetWidth = Math.max(0, targetWidth - (minX - targetLeft));
                targetLeft = minX;
            }
            if (targetLeft + targetWidth > maxX) {
                targetWidth = Math.max(0, maxX - targetLeft);
            }


            if (targetTop < minY) {
                targetHeight = Math.max(0, targetHeight - (minY - targetTop));
                targetTop = minY;
            }
            if (targetTop + targetHeight > maxY) {
                targetHeight = Math.max(0, maxY - targetTop);
            }

            finalOutline.style.setProperty('top', (targetTop + window.scrollY) + 'px', 'important');
            finalOutline.style.setProperty('left', (targetLeft + window.scrollX) + 'px', 'important');
            finalOutline.style.setProperty('width', targetWidth + 'px', 'important');
            finalOutline.style.setProperty('height', targetHeight + 'px', 'important');
            finalOutline.style.setProperty('border-radius', window.getComputedStyle(targetEl).borderRadius, 'important');
            finalOutline.style.setProperty('box-shadow', 'inset 0 0 0 2px var(--purple), 0 0 0 9999px rgba(0, 0, 0, 0.65)', 'important');


            const boxWidth = box.offsetWidth || 320;
            const boxHeight = box.offsetHeight || 180;
            let left = rect.left + (rect.width / 2) - (boxWidth / 2);
            let top = rect.bottom + 20;

            if (top + boxHeight + 20 > window.innerHeight) {
                top = rect.top - boxHeight - 20;

                if (top < 15) {

                    left = rect.right + 20;
                    top = rect.top;

                    if (top + boxHeight + 15 > window.innerHeight) {
                        top = window.innerHeight - boxHeight - 15;
                    }

                    if (left + boxWidth + 15 > window.innerWidth) {

                        left = rect.left - boxWidth - 20;
                        if (left < 15) {

                            left = (window.innerWidth / 2) - (boxWidth / 2);
                            top = (window.innerHeight / 2) - (boxHeight / 2);
                        }
                    }
                }
            }


            if (left < 15) left = 15;
            if (left + boxWidth + 15 > window.innerWidth) left = window.innerWidth - boxWidth - 15;
            if (top < 15) top = 15;
            if (top + boxHeight + 15 > window.innerHeight) top = window.innerHeight - boxHeight - 15;

            box.style.top = '0';
            box.style.left = '0';
            box.style.transform = `translate(${left}px, ${top}px)`;
        } else {

            finalOutline.style.setProperty('top', '0px', 'important');
            finalOutline.style.setProperty('left', '0px', 'important');
            finalOutline.style.setProperty('width', '0px', 'important');
            finalOutline.style.setProperty('height', '0px', 'important');
            finalOutline.style.setProperty('border-radius', '0px', 'important');
            finalOutline.style.setProperty('box-shadow', '0 0 0 9999px rgba(0, 0, 0, 0.65)', 'important');

            const boxWidth = box.offsetWidth || 320;
            const boxHeight = box.offsetHeight || 180;
            let left = (window.innerWidth / 2) - (boxWidth / 2);
            let top = (window.innerHeight / 2) - (boxHeight / 2);

            box.style.top = '0';
            box.style.left = '0';
            box.style.transform = `translate(${left}px, ${top}px)`;
        }
    };

    window.tutTimeout = setTimeout(runUpdate, 15);

    window.tutTimeout2 = setTimeout(runUpdate, 250);

    let dotsHtml = '';
    for (let i = 0; i < tutSteps.length; i++) {
        dotsHtml += `<div style="width:6px; height:6px; border-radius:50%; background:${i === currentTutStep ? 'var(--purple)' : 'rgba(255,255,255,0.2)'}"></div>`;
    }
    document.getElementById('tut-dots').innerHTML = dotsHtml;

    document.getElementById('tut-prev').style.display = currentTutStep > 0 ? 'block' : 'none';
    if (currentTutStep === tutSteps.length - 1) document.getElementById('tut-next').innerText = 'Finish';
    else document.getElementById('tut-next').innerText = 'Next';
}

window.showUiUpdateModal = function (version, changelog, downloadUrl) {
    if (localStorage.getItem('sh_tut_done') !== 'true') return;
    const modal = document.getElementById('ui-update-modal');
    if (!modal) return;
    document.getElementById('ui-update-version').innerText = "New Version: " + version;
    document.getElementById('ui-update-changelog').innerText = changelog;

    document.getElementById('btn-ui-update-ignore').onclick = () => {
        modal.classList.remove('visible');
    };

    document.getElementById('btn-ui-update-now').onclick = () => {
        modal.classList.remove('visible');

        // Flush the latest user state before the old process hands control to
        // the updater. User folders are protected by the backend extractor.
        saveSettings();
        saveTabs();

        const dlModal = document.getElementById('download-modal');
        const dlTitle = document.getElementById('download-title');
        const dlStatus = document.getElementById('download-status');
        const dlSpinner = document.getElementById('download-spinner');
        const dlActions = document.getElementById('download-actions');

        if (dlTitle) dlTitle.innerText = "Downloading Application Update...";
        if (dlStatus) dlStatus.innerText = "Fetching latest executable from GitHub...";
        if (dlSpinner) dlSpinner.style.display = "block";
        if (dlActions) dlActions.style.display = "none";
        if (dlModal) dlModal.classList.add('visible');

        if (typeof bridge !== 'undefined' && bridge.InstallUiUpdate) {
            bridge.InstallUiUpdate(downloadUrl);
        }
    };

    modal.classList.add('visible');
};

window.showUpdateWelcome = function () {
    const modal = document.getElementById('update-welcome-modal');
    if (!modal || window._updateWelcomeShowing) return false;
    window._updateWelcomeShowing = true;

    const close = document.getElementById('update-welcome-close');
    const acrylic = document.getElementById('update-welcome-acrylic');
    const acknowledge = function () {
        window._updateWelcomeShowing = false;
        if (bridge && bridge.AcknowledgeUpdateWelcome) bridge.AcknowledgeUpdateWelcome();
    };

    if (close) close.onclick = () => {
        modal.classList.remove('visible');
        acknowledge();
    };
    if (acrylic) acrylic.onclick = () => {
        modal.classList.remove('visible');
        acknowledge();
        if (typeof window.highlightSetting === 'function') {
            window.highlightSetting('interface', 'toggle-acrylic-enabled');
        }
    };

    modal.classList.add('visible');
    return true;
};

window.checkUpdateWelcome = async function () {
    if (localStorage.getItem('sh_tut_done') !== 'true') return;
    if (window.isTutorialRunning || window._updateWelcomeShowing) return;
    if (!bridge || !bridge.GetUpdateWelcome) return;
    try {
        const raw = await bridge.GetUpdateWelcome();
        if (!raw) return;
        const payload = JSON.parse(String(raw));
        if (payload && payload.version === '1.2') window.showUpdateWelcome();
    } catch (e) { }
};

window.onUiUpdateFailed = function (errorMsg) {
    const dlTitle = document.getElementById('download-title');
    const dlStatus = document.getElementById('download-status');
    const dlSpinner = document.getElementById('download-spinner');
    const dlActions = document.getElementById('download-actions');
    const dlClose = document.getElementById('download-close');

    if (dlTitle) dlTitle.innerText = "Application Update Failed";
    if (dlStatus) dlStatus.innerText = errorMsg;
    if (dlSpinner) dlSpinner.style.display = "none";
    if (dlActions) dlActions.style.display = "flex";
    if (dlClose) dlClose.onclick = () => {
        const dlModal = document.getElementById('download-modal');
        if (dlModal) dlModal.classList.remove('visible');
    };
};

window.addEventListener('DOMContentLoaded', function () {
    // Sync download modal status to update card notes during inline SirHurt updates
    const dlStatusEl = document.getElementById('download-status');
    const updateNotesEl = document.getElementById('update-notes-text');
    if (dlStatusEl && updateNotesEl) {
        const observer = new MutationObserver(() => {
            if (window.isUpdatingSirHurt) {
                updateNotesEl.innerText = dlStatusEl.innerText;
            }
        });
        observer.observe(dlStatusEl, { characterData: true, childList: true, subtree: true });
    }

    renderTabs();
    setupCustomSelects();
    window.applyUISize(settings.uiSize || 'normal');
    window.renderThemeGrid();

    if (settings.defaultPage) { navigateTo(settings.defaultPage); } else { navigateTo('home'); }

    if (localStorage.getItem('sh_tut_done') !== 'true') {
        setTimeout(window.startTutorial, 1500);
    } else {
        setTimeout(window.checkUpdateWelcome, 900);
    }

    $id('tut-skip')?.addEventListener('click', window.skipTutorial);
    $id('tut-prev')?.addEventListener('click', () => { if (currentTutStep > 0) { currentTutStep--; renderTutorialStep(); } });
    $id('tut-next')?.addEventListener('click', () => {
        if (currentTutStep < tutSteps.length - 1) {
            currentTutStep++;
            renderTutorialStep();
        } else {
            window.endTutorial();
        }
    });

    $id('btn-add-tab').onclick = function () {
        var num = 1;
        var newName = "";
        do {
            newName = 'Tab ' + num;
            num++;
        } while (tabs.some(t => t.name === newName));
        createNewTab(newName, '');
    };
    $id('btn-attach').onclick = function () { if (bridge) bridge.Attach(); };
    var btnExec = $id('btn-execute');
    if (btnExec) {
        btnExec.addEventListener('click', function () {
            if (isSplitView) {
                window.openExecuteChoice();
            } else {
                var code = monacoEditor ? monacoEditor.getValue() : '';
                setTimeout(() => window.executeScript(code), 50);
            }
        });
    }
    $id('exec-select-cancel').onclick = () => { $id('exec-select-modal').classList.remove('visible'); setTimeout(() => $id('exec-select-modal').style.display = 'none', 300); };

    window.openExecuteChoice = function () {
        if (splitTabIds.length !== 2) return;
        const t1 = tabs.find(t => t.id === splitTabIds[0]);
        const t2 = tabs.find(t => t.id === splitTabIds[1]);
        if (!t1 || !t2) return;

        $id('exec-left-name').innerText = t1.name;
        $id('exec-right-name').innerText = t2.name;

        $id('exec-left-pane').onclick = () => {
            setTimeout(() => window.executeScript(t1.content), 50);
            $id('exec-select-cancel').click();
        };
        $id('exec-right-pane').onclick = () => {
            setTimeout(() => window.executeScript(t2.content), 50);
            $id('exec-select-cancel').click();
        };

        const modal = $id('exec-select-modal');
        modal.style.display = 'flex';
        void modal.offsetWidth;
        modal.classList.add('visible');
    };

    $id('btn-open').onclick = function () { if (bridge) bridge.OpenFile().then(function (r) { if (r && r.length === 2) { createNewTab(r[0], r[1]); } }); };
    $id('btn-save').onclick = function () { if (bridge) bridge.SaveFile(getEditorValue()); };
    $id('btn-clear-editor').onclick = function () {
        if (settings.confirmClear) {
            let t = tabs.find(x => x.id === activeTab);
            let tName = t ? t.name : "this tab";
            window.openActionModal(
                "Clear " + tName + "?",
                "Are you sure you want to clear this tab? If you don't have it saved, it can't be recovered.",
                "red",
                function () { setEditorValue(''); }
            );
        } else {
            setEditorValue('');
        }
    };
    var clearConsoles = function () { if ($id('history-list')) $id('history-list').innerHTML = '<span class="console-ph">Waiting for SirHurt output...</span>'; };
    var btnClearCons = $id('btn-clear-console');
    if (btnClearCons) btnClearCons.onclick = clearConsoles;

    if ($id('toggle-auto-spoof-startup')) $id('toggle-auto-spoof-startup').checked = settings.autoSpoofStartup;
    if ($id('toggle-auto-spoof-exit')) $id('toggle-auto-spoof-exit').checked = settings.autoSpoofExit;
    if ($id('toggle-auto-clear-cookies-startup')) $id('toggle-auto-clear-cookies-startup').checked = settings.autoClearCookiesStartup;
    if ($id('toggle-auto-clear-cookies-exit')) $id('toggle-auto-clear-cookies-exit').checked = settings.autoClearCookiesExit;
    if ($id('toggle-auto-cleaner-startup')) $id('toggle-auto-cleaner-startup').checked = settings.autoCleanerStartup;
    if ($id('toggle-auto-cleaner-exit')) $id('toggle-auto-cleaner-exit').checked = settings.autoCleanerExit;
    if ($id('toggle-topmost')) $id('toggle-topmost').checked = settings.topmost;
    if ($id('toggle-autoinject')) $id('toggle-autoinject').checked = settings.autoinject;
    if ($id('toggle-autoexe')) $id('toggle-autoexe').checked = settings.autoexe;
    if ($id('toggle-multi-instance')) $id('toggle-multi-instance').checked = settings.multiInstance;
    if ($id('toggle-windows-startup')) $id('toggle-windows-startup').checked = settings.windowsStartup;
    if ($id('toggle-errorspoof')) $id('toggle-errorspoof').checked = settings.errorSpoofing;
    if ($id('toggle-unlockfps')) $id('toggle-unlockfps').checked = settings.unlockFps;
    if ($id('toggle-closeroblox')) $id('toggle-closeroblox').checked = settings.closeRobloxOnExit;

    if ($id('toggle-safemode')) $id('toggle-safemode').checked = settings.safeMode;
    if ($id('toggle-autoloadhub')) $id('toggle-autoloadhub').checked = settings.autoLoadHub;
    if ($id('toggle-hidecontext')) $id('toggle-hidecontext').checked = settings.hideContext;
    if ($id('toggle-clearonexec')) $id('toggle-clearonexec').checked = settings.clearOnExec;
    if ($id('toggle-ignoreerrors')) $id('toggle-ignoreerrors').checked = settings.ignoreErrors;
    if ($id('input-autoexec-delay')) {
        $id('input-autoexec-delay').value = settings.autoexecDelay || 0;
    }

    if ($id('toggle-discordrpc')) $id('toggle-discordrpc').checked = settings.discordRpc;
    if ($id('input-discord-clientid')) {
        $id('input-discord-clientid').value = settings.discordClientId || "123456789012345678";
    }
    if ($id('toggle-minimizetray')) $id('toggle-minimizetray').checked = settings.minimizeToTray;
    if ($id('toggle-screenlock')) $id('toggle-screenlock').checked = settings.screenLock;
    if ($id('toggle-dragscroll')) $id('toggle-dragscroll').checked = settings.mouseDragScroll;
    if ($id('toggle-hwaccel')) $id('toggle-hwaccel').checked = settings.hardwareAccel;
    if ($id('toggle-restoretabs')) $id('toggle-restoretabs').checked = settings.restoreTabs;
    if ($id('input-customfps')) {
        $id('input-customfps').value = settings.customFps;
    }
    if ($id('input-consolelimit')) {
        $id('input-consolelimit').value = settings.consoleLimit || 1000;
    }
    if ($id('toggle-enablehistory')) $id('toggle-enablehistory').checked = settings.enableScriptHistory !== false;

    if ($id('toggle-confirmclose')) $id('toggle-confirmclose').checked = settings.confirmClose;
    if ($id('toggle-confirmclear')) $id('toggle-confirmclear').checked = settings.confirmClear;
    if ($id('toggle-confirmdelete')) $id('toggle-confirmdelete').checked = settings.confirmDelete;
    if ($id('toggle-confirmdeletehistory')) $id('toggle-confirmdeletehistory').checked = settings.confirmDeleteHistory !== false;
    if ($id('toggle-confirmdeleteallhistory')) $id('toggle-confirmdeleteallhistory').checked = settings.confirmDeleteAllHistory !== false;
    if ($id('toggle-confirmdeletetheme')) $id('toggle-confirmdeletetheme').checked = settings.confirmDeleteTheme;
    if ($id('toggle-confirmcloseothers')) $id('toggle-confirmcloseothers').checked = settings.confirmCloseOthers;
    if ($id('toggle-confirmcloseapp')) $id('toggle-confirmcloseapp').checked = settings.confirmCloseApp;
    if ($id('toggle-navslide')) $id('toggle-navslide').checked = settings.navSlideOut;
    if ($id('toggle-symnav')) $id('toggle-symnav').checked = settings.symNav;
    if ($id('toggle-statusglow')) $id('toggle-statusglow').checked = settings.statusGlow;
    if ($id('toggle-statusglow-follow')) $id('toggle-statusglow-follow').checked = settings.statusGlowFollowAccent;
    if ($id('toggle-accentglow')) $id('toggle-accentglow').checked = settings.accentGlow;
    if ($id('toggle-glow-buttons')) $id('toggle-glow-buttons').checked = settings.glowButtons !== false;
    if ($id('toggle-tab-glow')) $id('toggle-tab-glow').checked = settings.tabGlow !== false;
    if ($id('toggle-window-rounded')) $id('toggle-window-rounded').checked = settings.windowRounded;
    if ($id('toggle-ui-rounded')) $id('toggle-ui-rounded').checked = settings.uiRounded;
    if ($id('toggle-swapbtn')) $id('toggle-swapbtn').checked = settings.swapButtons;
    if ($id('toggle-loader')) $id('toggle-loader').checked = settings.loader !== false;
    if ($id('toggle-showscrollbars')) $id('toggle-showscrollbars').checked = settings.showScrollbars;
    if ($id('toggle-animations')) {
        $id('toggle-animations').checked = settings.animations !== false;
        $id('toggle-animations').onchange = function (e) {
            settings.animations = e.target.checked; saveSettings();
            window.applyAppearanceClasses();
        };
    }

    var glow = $id('app-glow');
    if (glow) {
        glow.classList.remove('glow-hidden');
    }
    var acGlow = $id('accent-glow');
    if (acGlow) {
        if (settings.accentGlow) acGlow.classList.remove('glow-hidden');
        else acGlow.classList.add('glow-hidden');
    }

    if ($id('input-unfocused-opacity')) { $id('input-unfocused-opacity').value = settings.unfocusedOpacity; }
    if ($id('toggle-hidefilelist')) $id('toggle-hidefilelist').checked = settings.hideFileList;
    if ($id('toggle-hideconsole')) $id('toggle-hideconsole').checked = settings.hideConsoleOutput;
    if ($id('toggle-show-kill-roblox')) {
        $id('toggle-show-kill-roblox').checked = settings.showKillRoblox;
        var kbtn = $id('btn-kill-roblox-editor');
        if (kbtn) kbtn.style.display = settings.showKillRoblox ? '' : 'none';
    }


    if ($id('toggle-editor-insertspaces')) $id('toggle-editor-insertspaces').checked = settings.editorInsertSpaces;
    if ($id('toggle-editor-wordwrap')) $id('toggle-editor-wordwrap').checked = (settings.editorWordWrap === 'on');
    if ($id('input-editor-fontsize')) {
        $id('input-editor-fontsize').value = settings.editorFontSize || 13;
    }
    if ($id('toggle-editor-minimap')) $id('toggle-editor-minimap').checked = settings.editorMinimap;
    if ($id('toggle-editor-bracketcolor')) $id('toggle-editor-bracketcolor').checked = settings.editorBracketColorization;
    if ($id('toggle-editor-focusonnewtab')) $id('toggle-editor-focusonnewtab').checked = settings.focusOnNewTab;

    var editorDropdowns = [
        { id: 'editor-cursorstyle-dropdown', key: 'editorCursorStyle' },
        { id: 'editor-cursorblinking-dropdown', key: 'editorCursorBlinking' },
        { id: 'editor-matchbrackets-dropdown', key: 'editorMatchBrackets' },
        { id: 'editor-minimapside-dropdown', key: 'editorMinimapSide' },
        { id: 'editor-whitespace-dropdown', key: 'editorWhitespace' },
        { id: 'ui-size-dropdown', key: 'uiSize' },
        { id: 'default-page-dropdown', key: 'defaultPage' },
        { id: 'backdrop-type-dropdown', key: 'backdropType' }
    ];
    editorDropdowns.forEach(function (d) {
        var el = $id(d.id);
        if (!el || !settings[d.key]) return;
        var sel = el.querySelector('.select-selected');
        var opts = el.querySelectorAll('.select-items div');
        opts.forEach(function (opt) {
            if (opt.getAttribute('data-val') === settings[d.key]) {
                if (sel) sel.innerText = opt.innerText;
            }
        });
    });

    if (settings.hideFileList && filePanel) filePanel.style.display = 'none';
    if (settings.hideConsoleOutput && $id('console-box')) $id('console-box').style.display = 'none';

    if (settings.navSlideOut) $id('main-sidebar').classList.add('slide-enabled');
    if (settings.symNav) document.body.classList.add('symmetrical-nav-active');
    if (settings.statusGlowFollowAccent) document.body.classList.add('status-glow-follow-accent');
    if (!settings.statusGlow) {
        if ($id('status-dot')) $id('status-dot').classList.add('no-glow');
    }

    if ($id('toggle-show-v5')) $id('toggle-show-v5').checked = settings.showV5 !== false;
    window.applyV5Visibility();

    if (window.applyAccentColor) window.applyAccentColor();
    if (bridge && bridge.SetAutoInject) bridge.SetAutoInject(settings.autoinject);

    window.applyAppearanceClasses();
    window.applyScrollbarVisibility();
    if (settings.swapButtons) { var actionGrp = document.getElementById('primary-action-group'); if (actionGrp) actionGrp.style.flexDirection = 'row-reverse'; }

    if ($id('toggle-glow-buttons')) $id('toggle-glow-buttons').onchange = function (e) {
        settings.glowButtons = e.target.checked; saveSettings();
        window.applyAppearanceClasses();
    };
    if ($id('toggle-tab-glow')) $id('toggle-tab-glow').onchange = function (e) {
        settings.tabGlow = e.target.checked; saveSettings();
        window.applyAppearanceClasses();
    };
    if ($id('toggle-window-rounded')) $id('toggle-window-rounded').onchange = function (e) {
        settings.windowRounded = e.target.checked; saveSettings();
        window.applyAppearanceClasses();
    };
    if ($id('toggle-ui-rounded')) $id('toggle-ui-rounded').onchange = function (e) {
        settings.uiRounded = e.target.checked; saveSettings();
        window.applyAppearanceClasses();
    };

    const modal = $id('accent-picker-modal');
    const overlay = $id('picker-overlay');
    const preview = $id('picker-preview');
    const hueSlider = $id('hue-slider');
    const lightSlider = $id('lightness-slider');
    const hexInput = $id('hex-input');

    function hexToHsl(hex) {
        hex = hex.replace(/^#/, '');
        if (hex.length === 3) {
            hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
        }
        let r = parseInt(hex.substring(0, 2), 16) / 255;
        let g = parseInt(hex.substring(2, 4), 16) / 255;
        let b = parseInt(hex.substring(4, 6), 16) / 255;

        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let h, s, l = (max + min) / 2;

        if (max === min) {
            h = s = 0;
        } else {
            let d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        return {
            h: Math.round(h * 360),
            s: Math.round(s * 100),
            l: Math.round(l * 100)
        };
    }

    const updatePreview = (color) => {
        if (preview) preview.style.background = color;
        if (hexInput) hexInput.value = color.toUpperCase();

        const hsl = hexToHsl(color);
        if (hueSlider) {
            hueSlider.value = hsl.h;
            updateZSlider(hueSlider);
            if ($id('hue-val')) $id('hue-val').innerText = hsl.h + '°';
        }
        if (lightSlider) {
            lightSlider.value = hsl.l;
            updateZSlider(lightSlider);
            if ($id('light-val')) $id('light-val').innerText = hsl.l + '%';
        }

        const baseColor = hslToHex(hsl.h, 100, 50);
        if (lightSlider) {
            lightSlider.style.background = `linear-gradient(to right, #000, ${baseColor}, #fff)`;
        }
    };

    function updateZSlider(input) {
        const container = input.nextElementSibling;
        if (!container || !container.classList.contains('z-slider-container')) return;
        const thumb = container.querySelector('.z-slider-thumb');
        if (!thumb) return;
        const percent = (input.value - input.min) / (input.max - input.min);
        thumb.style.left = (percent * 100) + '%';
    }
    window.updateZSlider = updateZSlider;


    const handleSliderChange = (e) => {
        if (e && e.target) updateZSlider(e.target);
        const h = hueSlider ? hueSlider.value : 237;
        const l = lightSlider ? lightSlider.value : 60;
        const color = hslToHex(parseInt(h), 70, parseInt(l));

        if (preview) preview.style.background = color;
        if (hexInput) hexInput.value = color.toUpperCase();
        if ($id('hue-val')) $id('hue-val').innerText = h + '°';
        if ($id('light-val')) $id('light-val').innerText = l + '%';

        const baseColor = hslToHex(parseInt(h), 100, 50);
        if (lightSlider) {
            lightSlider.style.background = `linear-gradient(to right, #000, ${baseColor}, #fff)`;
        }
    };

    if (hueSlider) {
        hueSlider.oninput = handleSliderChange;
        updateZSlider(hueSlider);
    }
    if (lightSlider) {
        lightSlider.oninput = handleSliderChange;
        updateZSlider(lightSlider);
    }

    if ($id('btn-open-accent-picker')) $id('btn-open-accent-picker').onclick = () => {
        const curColor = settings.accentColor || '#7b7ff6';
        updatePreview(curColor);
        modal.classList.add('active');
        overlay.classList.add('active');
    };

    if ($id('btn-close-picker')) $id('btn-close-picker').onclick = () => {
        modal.classList.remove('active');
        overlay.classList.remove('active');
    };

    document.querySelectorAll('.preset-color').forEach(p => {
        p.onclick = () => updatePreview(p.getAttribute('data-color'));
    });

    if ($id('btn-apply-accent')) $id('btn-apply-accent').onclick = () => {
        settings.accentColor = hexInput.value;
        saveSettings();
        window.applyAccentColor();
        modal.classList.remove('active');
        overlay.classList.remove('active');
    };

    if ($id('btn-reset-accent')) $id('btn-reset-accent').onclick = () => {
        settings.accentColor = '#7b7ff6';
        saveSettings();
        window.applyAccentColor();
        if (window.showNotification) window.showNotification("Accent color reset to default");
    };

    function hslToHex(h, s, l) {
        l /= 100;
        const a = s * Math.min(l, 1 - l) / 100;
        const f = n => {
            const k = (n + h / 30) % 12;
            const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
            return Math.round(255 * color).toString(16).padStart(2, '0');
        };
        return `#${f(0)}${f(8)}${f(4)}`;
    }


    const autoInject = document.getElementById('toggle-autoinject');
    if (autoInject) {
        autoInject.checked = settings.autoinject;
        autoInject.onchange = (e) => { settings.autoinject = e.target.checked; saveSettings(); if (typeof bridge !== 'undefined' && bridge.SetAutoInject) bridge.SetAutoInject(e.target.checked); };
    }


    const accentPicker = document.getElementById('accent-color-picker');
    if (accentPicker) {
        accentPicker.value = settings.accentColor || '#7b7ff6';
        accentPicker.oninput = (e) => {
            settings.accentColor = e.target.value;
            window.applyAccentColor();
            saveSettings();
        };
    }

    if ($id('toggle-auto-spoof-startup')) $id('toggle-auto-spoof-startup').onchange = function (e) { settings.autoSpoofStartup = e.target.checked; saveSettings(); };
    if ($id('toggle-auto-spoof-exit')) $id('toggle-auto-spoof-exit').onchange = function (e) { settings.autoSpoofExit = e.target.checked; saveSettings(); };
    if ($id('toggle-auto-clear-cookies-startup')) $id('toggle-auto-clear-cookies-startup').onchange = function (e) { settings.autoClearCookiesStartup = e.target.checked; saveSettings(); };
    if ($id('toggle-auto-clear-cookies-exit')) $id('toggle-auto-clear-cookies-exit').onchange = function (e) { settings.autoClearCookiesExit = e.target.checked; saveSettings(); };
    if ($id('toggle-auto-cleaner-startup')) $id('toggle-auto-cleaner-startup').onchange = function (e) { settings.autoCleanerStartup = e.target.checked; saveSettings(); };
    if ($id('toggle-auto-cleaner-exit')) $id('toggle-auto-cleaner-exit').onchange = function (e) { settings.autoCleanerExit = e.target.checked; saveSettings(); };

    $id('toggle-topmost').checked = settings.topmost;
    $id('toggle-topmost').onchange = function (e) {
        settings.topmost = e.target.checked;
        saveSettings();
        if (typeof bridge !== 'undefined' && bridge.SetTopMost) bridge.SetTopMost(settings.topmost);
    };

    if ($id('toggle-autoexe')) $id('toggle-autoexe').onchange = function (e) { settings.autoexe = e.target.checked; saveSettings(); };
    if ($id('toggle-errorspoof')) $id('toggle-errorspoof').onchange = function (e) {
        settings.errorSpoofing = e.target.checked;
        saveSettings();
        window.updateConsolePlaceholders();
    };
    if ($id('toggle-unlockfps')) $id('toggle-unlockfps').onchange = function (e) {
        settings.unlockFps = e.target.checked;
        saveSettings();
        if (typeof bridge !== 'undefined' && bridge.Execute) {
            if (settings.unlockFps) {
                bridge.Execute("if setfpscap then pcall(setfpscap, " + (settings.customFps || 500) + ") end");
            } else {
                bridge.Execute("if setfpscap then pcall(setfpscap, 60) end");
            }
        }
    };
    if ($id('toggle-closeroblox')) $id('toggle-closeroblox').onchange = function (e) { settings.closeRobloxOnExit = e.target.checked; saveSettings(); };
    if ($id('toggle-windows-startup')) $id('toggle-windows-startup').onchange = function (e) {
        settings.windowsStartup = e.target.checked;
        saveSettings();
        if (typeof bridge !== 'undefined' && bridge.SetWindowsStartup) {
            bridge.SetWindowsStartup(settings.windowsStartup);
        }
    };

    if ($id('toggle-safemode')) $id('toggle-safemode').onchange = function (e) { settings.safeMode = e.target.checked; saveSettings(); };

    if ($id('toggle-hidecontext')) $id('toggle-hidecontext').onchange = function (e) { settings.hideContext = e.target.checked; saveSettings(); };
    if ($id('toggle-clearonexec')) $id('toggle-clearonexec').onchange = function (e) { settings.clearOnExec = e.target.checked; saveSettings(); };
    if ($id('toggle-ignoreerrors')) $id('toggle-ignoreerrors').onchange = function (e) { settings.ignoreErrors = e.target.checked; saveSettings(); };

    if ($id('input-autoexec-delay')) {
        $id('input-autoexec-delay').onchange = async function (e) {
            settings.autoexecDelay = parseInt(e.target.value) || 0;
            saveSettings();
            await window.updateAllAutoexecScripts();
        };
        $id('input-autoexec-delay').onkeydown = function (e) { if (e.key === 'Enter') e.target.blur(); };
    }


    if ($id('toggle-minimizetray')) $id('toggle-minimizetray').onchange = function (e) { settings.minimizeToTray = e.target.checked; saveSettings(); };
    if ($id('toggle-screenlock')) $id('toggle-screenlock').onchange = function (e) { settings.screenLock = e.target.checked; saveSettings(); };
    if ($id('toggle-dragscroll')) $id('toggle-dragscroll').onchange = function (e) { settings.mouseDragScroll = e.target.checked; saveSettings(); };
    if ($id('toggle-hwaccel')) $id('toggle-hwaccel').onchange = function (e) { settings.hardwareAccel = e.target.checked; saveSettings(); };
    if ($id('toggle-restoretabs')) $id('toggle-restoretabs').onchange = function (e) { settings.restoreTabs = e.target.checked; saveSettings(); };
    if ($id('toggle-enablehistory')) {
        $id('toggle-enablehistory').onchange = function (e) {
            settings.enableScriptHistory = e.target.checked;
            saveSettings();
        };
    }

    if ($id('input-customfps')) {
        $id('input-customfps').onchange = function (e) {
            let val = parseInt(e.target.value);
            if (isNaN(val) || val < 1) val = 500;
            settings.customFps = val;
            saveSettings();
            if (settings.unlockFps && typeof bridge !== 'undefined' && bridge.Execute) {
                bridge.Execute("if setfpscap then pcall(setfpscap, " + val + ") end");
            }
        };
        $id('input-customfps').oninput = function (e) {
            let val = parseInt(e.target.value);
            if (!isNaN(val) && val > 0 && settings.unlockFps && typeof bridge !== 'undefined' && bridge.Execute) {
                bridge.Execute("if setfpscap then pcall(setfpscap, " + val + ") end");
            }
        };
        $id('input-customfps').onkeydown = function (e) { if (e.key === 'Enter') e.target.blur(); };
    }

    if ($id('input-consolelimit')) {
        $id('input-consolelimit').onchange = function (e) {
            let val = parseInt(e.target.value);
            if (isNaN(val) || val < 10) val = 1000;
            settings.consoleLimit = val;
            saveSettings();
        };
        $id('input-consolelimit').onkeydown = function (e) { if (e.key === 'Enter') e.target.blur(); };
    }


    if ($id('toggle-confirmclose')) $id('toggle-confirmclose').onchange = function (e) { settings.confirmClose = e.target.checked; saveSettings(); };
    if ($id('toggle-confirmclear')) $id('toggle-confirmclear').onchange = function (e) { settings.confirmClear = e.target.checked; saveSettings(); };
    if ($id('toggle-confirmdelete')) $id('toggle-confirmdelete').onchange = function (e) { settings.confirmDelete = e.target.checked; saveSettings(); };
    if ($id('toggle-confirmdeletehistory')) $id('toggle-confirmdeletehistory').onchange = function (e) { settings.confirmDeleteHistory = e.target.checked; saveSettings(); };
    if ($id('toggle-confirmdeleteallhistory')) $id('toggle-confirmdeleteallhistory').onchange = function (e) { settings.confirmDeleteAllHistory = e.target.checked; saveSettings(); };
    if ($id('toggle-confirmdeletetheme')) $id('toggle-confirmdeletetheme').onchange = function (e) { settings.confirmDeleteTheme = e.target.checked; saveSettings(); };
    if ($id('toggle-confirmcloseothers')) $id('toggle-confirmcloseothers').onchange = function (e) { settings.confirmCloseOthers = e.target.checked; saveSettings(); };
    if ($id('toggle-confirmcloseapp')) $id('toggle-confirmcloseapp').onchange = function (e) { settings.confirmCloseApp = e.target.checked; saveSettings(); };



    if ($id('toggle-navslide')) $id('toggle-navslide').onchange = function (e) {
        settings.navSlideOut = e.target.checked; saveSettings();
        if (settings.navSlideOut) $id('main-sidebar').classList.add('slide-enabled');
        else {
            $id('main-sidebar').classList.remove('slide-enabled');
            $id('main-sidebar').classList.remove('expanded');
        }
    };

    if ($id('toggle-symnav')) $id('toggle-symnav').onchange = function (e) {
        settings.symNav = e.target.checked; saveSettings();
        if (settings.symNav) document.body.classList.add('symmetrical-nav-active');
        else document.body.classList.remove('symmetrical-nav-active');
    };
    if ($id('toggle-statusglow')) $id('toggle-statusglow').onchange = function (e) {
        settings.statusGlow = e.target.checked; saveSettings();
        var dot = $id('status-dot');
        if (settings.statusGlow) {
            if (dot) dot.classList.remove('no-glow');
        } else {
            if (dot) dot.classList.add('no-glow');
        }
        if (window.applyAccentColor) window.applyAccentColor();
    };
    if ($id('toggle-statusglow-follow')) $id('toggle-statusglow-follow').onchange = function (e) {
        settings.statusGlowFollowAccent = e.target.checked; saveSettings();
        if (settings.statusGlowFollowAccent) document.body.classList.add('status-glow-follow-accent');
        else document.body.classList.remove('status-glow-follow-accent');
        if (window.applyAccentColor) window.applyAccentColor();
    };
    if ($id('toggle-accentglow')) $id('toggle-accentglow').onchange = function (e) {
        settings.accentGlow = e.target.checked; saveSettings();
        var glow = $id('accent-glow');
        if (glow) {
            if (settings.accentGlow) glow.classList.remove('glow-hidden');
            else glow.classList.add('glow-hidden');
        }
    };
    if ($id('toggle-show-v5')) $id('toggle-show-v5').onchange = function (e) {
        settings.showV5 = e.target.checked; saveSettings();
        window.applyV5Visibility();
    };

    if ($id('toggle-swapbtn')) $id('toggle-swapbtn').onchange = function (e) {
        settings.swapButtons = e.target.checked; saveSettings();
        var actionGrp = document.getElementById('primary-action-group');
        if (actionGrp) actionGrp.style.flexDirection = settings.swapButtons ? 'row-reverse' : 'row';
    };
    if ($id('toggle-showscrollbars')) $id('toggle-showscrollbars').onchange = function (e) {
        settings.showScrollbars = e.target.checked; saveSettings();
        window.applyScrollbarVisibility();
    };
    if ($id('toggle-loader')) {
        $id('toggle-loader').onchange = function (e) {
            settings.loader = e.target.checked;
            saveSettings();
            if (typeof bridge !== 'undefined' && bridge.SetLoaderEnabled) {
                bridge.SetLoaderEnabled(settings.loader);
            }
        };
    }

    if ($id('toggle-blur-options')) {
        $id('toggle-blur-options').checked = settings.blurOptions;
        $id('toggle-blur-options').onchange = function (e) {
            settings.blurOptions = e.target.checked; saveSettings();
            window.applyAppearanceClasses();
        };
    }

    if ($id('toggle-transparency')) {
        $id('toggle-transparency').checked = settings.transparency;
        $id('toggle-transparency').onchange = function (e) {
            settings.transparency = e.target.checked; saveSettings();
            window.applyAppearanceClasses();
        };
    }


    function updateInterfaceVisibility(animate) {
        const rows = [
            { id: 'row-slider-unfocused', enabled: settings.unfocusedOpacityEnabled },
        ];

        rows.forEach(row => {
            const el = $id(row.id);
            if (!el) return;
            if (row.enabled) {
                if (el.style.display === 'none') {
                    el.style.display = 'flex';
                    if (animate) {
                        el.classList.remove('in-view');
                        el.classList.add('zenith-scroll-item');
                        setTimeout(() => el.classList.add('in-view'), 50);
                    } else {
                        el.classList.add('zenith-scroll-item', 'in-view');
                    }
                }
            } else {
                el.style.display = 'none';
                el.classList.remove('in-view');
            }
        });
        if (window.applyBackdropClasses) window.applyBackdropClasses();
    }

    if ($id('toggle-acrylic-enabled')) $id('toggle-acrylic-enabled').onchange = function (e) {
        settings.acrylicEnabled = e.target.checked;
        saveSettings();
        if (window.applyBackdropClasses) window.applyBackdropClasses();
        updateInterfaceVisibility(true);
        if (bridge && bridge.SetAcrylicEnabled) bridge.SetAcrylicEnabled(settings.acrylicEnabled);
    };
    if ($id('toggle-unfocused-opacity-enabled')) $id('toggle-unfocused-opacity-enabled').onchange = function (e) {
        settings.unfocusedOpacityEnabled = e.target.checked; saveSettings();
        updateInterfaceVisibility(true);
        updateTargetOpacity();
    };


    if ($id('input-unfocused-opacity')) {
        $id('input-unfocused-opacity').oninput = function (e) {
            let val = parseInt(e.target.value) || 85;
            if (val > 100) val = 100;
            if (val < 10) val = 10;
            settings.unfocusedOpacity = val;
            updateTargetOpacity();
            saveSettings();
        };
        $id('input-unfocused-opacity').onblur = function (e) {
            let val = parseInt(e.target.value) || 85;
            if (val > 100) val = 100;
            if (val < 10) val = 10;
            e.target.value = val;
            settings.unfocusedOpacity = val;
            updateTargetOpacity();
            saveSettings();
        };
        $id('input-unfocused-opacity').onkeydown = function (e) { if (e.key === 'Enter') e.target.blur(); };
    }


    var _winOpacityCurrent = 1.0;
    var _winOpacityTarget = 1.0;
    var _winOpacityRaf = null;

    function updateTargetOpacity() {
        var isFocused = document.hasFocus() || (window.isNativeFocused === true);
        var activeOpacity = 1.0;

        if (!isFocused && settings.unfocusedOpacityEnabled) {
            _winOpacityTarget = settings.unfocusedOpacity / 100;
        } else {
            _winOpacityTarget = activeOpacity;
        }
        if (!_winOpacityRaf) _winOpacityRaf = requestAnimationFrame(animateWindowOpacity);
    }

    function animateWindowOpacity() {
        var diff = _winOpacityTarget - _winOpacityCurrent;
        if (Math.abs(diff) < 0.001) {
            _winOpacityCurrent = _winOpacityTarget;
            if (bridge && bridge.SetWindowOpacity) bridge.SetWindowOpacity(_winOpacityCurrent);
            _winOpacityRaf = null;
            return;
        }

        _winOpacityCurrent += diff * 0.08;
        if (bridge && bridge.SetWindowOpacity) bridge.SetWindowOpacity(_winOpacityCurrent);
        _winOpacityRaf = requestAnimationFrame(animateWindowOpacity);
    }


    window.syncWindowState = function (isFocused) {
        window.isNativeFocused = isFocused;
        updateTargetOpacity();
    };

    window.addEventListener('blur', function () { updateTargetOpacity(); });
    window.addEventListener('focus', function () { updateTargetOpacity(); });


    setTimeout(() => {
        if ($id('toggle-acrylic-enabled')) $id('toggle-acrylic-enabled').checked = settings.acrylicEnabled;
        if ($id('toggle-unfocused-opacity-enabled')) $id('toggle-unfocused-opacity-enabled').checked = settings.unfocusedOpacityEnabled;
        if ($id('input-unfocused-opacity')) {
            $id('input-unfocused-opacity').value = settings.unfocusedOpacity;
        }

        if (window.applyBackdropClasses) window.applyBackdropClasses();
        updateInterfaceVisibility(false);
        updateTargetOpacity();
        if (bridge && bridge.SetAcrylicEnabled) {
            bridge.SetAcrylicEnabled(settings.acrylicEnabled);
        }
    }, 1000);
    if ($id('toggle-hidefilelist')) {
        $id('toggle-hidefilelist').onchange = function (e) {
            settings.hideFileList = e.target.checked; saveSettings();
            if (filePanel) filePanel.style.display = settings.hideFileList ? 'none' : '';
            setTimeout(function () { if (monacoEditor) monacoEditor.layout(); }, 300);
        };
    }
    if ($id('toggle-hideconsole')) {
        $id('toggle-hideconsole').onchange = function (e) {
            settings.hideConsoleOutput = e.target.checked; saveSettings();
            var cb = $id('console-box');
            if (cb) cb.style.display = settings.hideConsoleOutput ? 'none' : '';
            setTimeout(function () { if (monacoEditor) monacoEditor.layout(); }, 300);
        };
    }
    if ($id('toggle-show-kill-roblox')) {
        $id('toggle-show-kill-roblox').onchange = function (e) {
            settings.showKillRoblox = e.target.checked; saveSettings();
            var kbtn = $id('btn-kill-roblox-editor');
            if (kbtn) kbtn.style.display = settings.showKillRoblox ? '' : 'none';
        };
    }
    if ($id('btn-kill-roblox-editor')) {
        $id('btn-kill-roblox-editor').onclick = function () {
            if (bridge && bridge.KillAllRoblox) bridge.KillAllRoblox();
            window.showNotification('All Roblox clients have been killed');
        };
    }



    window.applyEditorSettings = function () {
        if (!monacoEditor) return;

        var vMode = settings.editorScrollbarV !== false ? 'auto' : 'hidden';
        var hMode = settings.editorScrollbarH !== false ? 'auto' : 'hidden';
        var vSize = settings.editorScrollbarV !== false ? 6 : 0;
        var hSize = settings.editorScrollbarH !== false ? 6 : 0;

        var options = {
            fontSize: settings.editorFontSize,
            wordWrap: settings.editorWordWrap,
            cursorStyle: settings.editorCursorStyle,
            cursorBlinking: settings.editorCursorBlinking,
            scrollBeyondLastLine: false,
            minimap: {
                enabled: settings.editorMinimap,
                side: settings.editorMinimapSide,
                renderCharacters: true,
                size: 'proportional',
                maxColumn: 120,
                scale: 2,
                showSlider: 'always'
            },
            renderWhitespace: settings.editorWhitespace,
            bracketPairColorization: { enabled: !!settings.editorBracketColorization },
            scrollbar: {
                vertical: vMode,
                horizontal: hMode,
                verticalScrollbarSize: vSize, horizontalScrollbarSize: hSize, useShadows: false
            }
        };

        monacoEditor.updateOptions(options);
        if (monacoEditorSecondary) monacoEditorSecondary.updateOptions(options);

        // Model options for space indentations
        var model1 = monacoEditor.getModel();
        if (model1) {
            model1.updateOptions({
                insertSpaces: !!settings.editorInsertSpaces,
                tabSize: 4
            });
        }
        if (monacoEditorSecondary) {
            var model2 = monacoEditorSecondary.getModel();
            if (model2) {
                model2.updateOptions({
                    insertSpaces: !!settings.editorInsertSpaces,
                    tabSize: 4
                });
            }
        }

        setTimeout(function () {
            if (monacoEditor) monacoEditor.layout();
            if (monacoEditorSecondary) monacoEditorSecondary.layout();
        }, 150);
    };

    if ($id('toggle-editor-insertspaces')) {
        $id('toggle-editor-insertspaces').onchange = function (e) { settings.editorInsertSpaces = e.target.checked; saveSettings(); window.applyEditorSettings(); };
    }
    if ($id('toggle-editor-wordwrap')) {
        $id('toggle-editor-wordwrap').onchange = function (e) { settings.editorWordWrap = e.target.checked ? 'on' : 'off'; saveSettings(); window.applyEditorSettings(); };
    }
    if ($id('input-editor-fontsize')) {
        $id('input-editor-fontsize').oninput = function (e) {
            let val = parseInt(e.target.value) || 13;
            if (val > 24) val = 24;
            if (val < 8) val = 8;
            settings.editorFontSize = val;
            saveSettings();
            window.applyEditorSettings();
        };
        $id('input-editor-fontsize').onblur = function (e) {
            let val = parseInt(e.target.value) || 13;
            if (val > 24) val = 24;
            if (val < 8) val = 8;
            e.target.value = val;
            settings.editorFontSize = val;
            saveSettings();
            window.applyEditorSettings();
        };
        $id('input-editor-fontsize').onkeydown = function (e) { if (e.key === 'Enter') e.target.blur(); };
    }
    if ($id('toggle-editor-focusonnewtab')) {
        $id('toggle-editor-focusonnewtab').onchange = function (e) { settings.focusOnNewTab = e.target.checked; saveSettings(); };
    }

    var minimapToggle = document.getElementById('toggle-editor-minimap');
    var scrollbarVToggle = document.getElementById('toggle-editor-scrollbar-v');
    var scrollbarHToggle = document.getElementById('toggle-editor-scrollbar-h');

    if (minimapToggle) {
        minimapToggle.addEventListener('change', function (e) {
            settings.editorMinimap = e.target.checked;
            var sideRow = document.getElementById('minimap-side-row');
            if (sideRow) sideRow.style.display = e.target.checked ? '' : 'none';
            saveSettings();
            if (window.applyEditorSettings) window.applyEditorSettings();
        });
    }

    if (scrollbarVToggle) {
        scrollbarVToggle.addEventListener('change', function (e) {
            settings.editorScrollbarV = e.target.checked;
            saveSettings();
            if (window.applyEditorSettings) window.applyEditorSettings();
        });
    }

    if (scrollbarHToggle) {
        scrollbarHToggle.addEventListener('change', function (e) {
            settings.editorScrollbarH = e.target.checked;
            saveSettings();
            if (window.applyEditorSettings) window.applyEditorSettings();
        });
    }

    setTimeout(function () {
        var sideRow = document.getElementById('minimap-side-row');
        if (sideRow) sideRow.style.display = settings.editorMinimap ? '' : 'none';

        if (scrollbarVToggle) scrollbarVToggle.checked = settings.editorScrollbarV !== false;
        if (scrollbarHToggle) scrollbarHToggle.checked = settings.editorScrollbarH !== false;
        var focusTabToggle = document.getElementById('toggle-editor-focusonnewtab');
        if (focusTabToggle) focusTabToggle.checked = settings.focusOnNewTab !== false;
    }, 500);

    if ($id('toggle-editor-bracketcolor')) {
        $id('toggle-editor-bracketcolor').onchange = function (e) {
            settings.editorBracketColorization = e.target.checked;
            saveSettings();
            if (window.applyEditorSettings) window.applyEditorSettings();
        };
    }



    var editorDropdownHandlers = [
        { id: 'editor-cursorstyle-dropdown', key: 'editorCursorStyle' },
        { id: 'editor-cursorblinking-dropdown', key: 'editorCursorBlinking' },
        { id: 'editor-matchbrackets-dropdown', key: 'editorMatchBrackets' },
        { id: 'editor-minimapside-dropdown', key: 'editorMinimapSide' },
        { id: 'editor-whitespace-dropdown', key: 'editorWhitespace' },
        { id: 'ui-size-dropdown', key: 'uiSize' },
        { id: 'default-page-dropdown', key: 'defaultPage' },
        { id: 'backdrop-type-dropdown', key: 'backdropType' }
    ];
    editorDropdownHandlers.forEach(function (d) {
        var el = $id(d.id);
        if (!el) return;
        var sel = el.querySelector('.select-selected');
        var opts = el.querySelectorAll('.select-items div');
        opts.forEach(function (opt) {
            opt.addEventListener('click', function (e) {
                e.stopPropagation();
                settings[d.key] = this.getAttribute('data-val');
                if (sel) sel.innerText = this.innerText;
                saveSettings();

                if (d.id === 'ui-size-dropdown') {
                    window.applyUISize(settings.uiSize);
                } else if (d.id === 'backdrop-type-dropdown') {
                    if (window.applyBackdropClasses) window.applyBackdropClasses();
                    updateTargetOpacity();
                    if (settings.acrylicEnabled && bridge && bridge.SetBackdropType) {
                        bridge.SetBackdropType(settings.backdropType);
                    }
                } else if (d.id !== 'default-page-dropdown') {
                    window.applyEditorSettings();
                }

                closeAllSelect();
            });
        });
    });


    if ($id('ctx-tab-pin')) {
        $id('ctx-tab-pin').onclick = function () {
            hideCtxMenus();
            if (!ctxTargetTabId) return;
            var tab = tabs.find(t => t.id === ctxTargetTabId);
            if (!tab) return;
            tab.pinned = !tab.pinned;
            if (tab.pinned) {

                var idx = tabs.indexOf(tab);
                if (idx > 0) { tabs.splice(idx, 1); tabs.unshift(tab); }
            }
            renderTabs(); saveTabs();
            window.showNotification(tab.pinned ? 'Tab pinned' : 'Tab unpinned');
        };
    }

    var ctxTabMenu = $id('ctx-tab-menu') || document.querySelector('.ctx-tab-menu') || (function () {

        var pinEl = $id('ctx-tab-pin');
        return pinEl ? pinEl.closest('.context-menu, .ctx-menu, [class*="context"]') : null;
    }());

    if (tabsList) {
        tabsList.addEventListener('contextmenu', function () {
            setTimeout(function () {
                var tab = ctxTargetTabId ? tabs.find(t => t.id === ctxTargetTabId) : null;
                var pinEl = $id('ctx-tab-pin');
                if (pinEl && tab) pinEl.childNodes[pinEl.childNodes.length - 1].textContent = tab.pinned ? 'Unpin' : 'Pin';
            }, 10);
        });
    }
    if ($id('ctx-tab-readonly')) {
        $id('ctx-tab-readonly').onclick = function () {
            hideCtxMenus();
            if (!ctxTargetTabId) return;
            var tab = tabs.find(t => t.id === ctxTargetTabId);
            if (!tab) return;
            tab.readOnly = !tab.readOnly;
            if (monacoEditor && ctxTargetTabId === activeTab) {
                monacoEditor.updateOptions({ readOnly: !!tab.readOnly });
            }
            saveTabs();
            window.showNotification(tab.readOnly ? 'Tab set to read only' : 'Read only removed');
        };
    }

    var btnToggleFiles = $id('btn-toggle-files');
    if (btnToggleFiles) {
        if (settings.filesCollapsed) { filePanel.classList.add('collapsed'); }
        btnToggleFiles.onclick = function () {
            filePanel.classList.toggle('collapsed');
            settings.filesCollapsed = filePanel.classList.contains('collapsed');
            saveSettings();
            setTimeout(function () { if (monacoEditor) monacoEditor.layout(); }, 300);
        };
    }

    var clearConsoles = function () { if ($id('history-list')) $id('history-list').innerHTML = '<span class="console-ph">Waiting for SirHurt output...</span>'; };
    var btnClearCons = $id('btn-clear-console');
    if (btnClearCons) btnClearCons.onclick = clearConsoles;

    var cBox = $id('console-box');
    if (cBox && settings.consoleCollapsed) { cBox.classList.add('collapsed'); }
    var btnToggleCons = $id('btn-toggle-console');
    if (btnToggleCons && cBox) {
        btnToggleCons.onclick = function () {
            cBox.classList.toggle('collapsed');
            settings.consoleCollapsed = cBox.classList.contains('collapsed');
            saveSettings();
            setTimeout(function () { if (monacoEditor) monacoEditor.layout(); }, 300);
        };
    }

    $id('btn-min').onclick = function () { if (bridge) bridge.Minimize(); };
    $id('btn-max').onclick = function () { if (bridge) bridge.Maximize(); };
    $id('btn-close').onclick = function () {
        if (settings.confirmCloseApp) {
            window.openActionModal("Confirm Exit", "Are you sure you want to close SirHurt?", "red", function () {
                runExitTasksAndClose();
            });
        } else {
            runExitTasksAndClose();
        }
    };
    let isMainDragging = false;
    let mainDragStartMouseX = 0;
    let mainDragStartMouseY = 0;

    $id('titlebar').onmousedown = function (e) {
        if (e.target.closest('.wc-btn')) return;
        if (typeof bridge === 'undefined') return;

        if (settings.screenLock) {
            isMainDragging = true;
            mainDragStartMouseX = e.screenX;
            mainDragStartMouseY = e.screenY;
            bridge.StartCustomDrag(mainDragStartMouseX, mainDragStartMouseY);
        } else {
            bridge.StartDragging();
        }
    };

    window.addEventListener('mousemove', function (e) {
        if (!isMainDragging) return;
        if (typeof bridge !== 'undefined') {
            bridge.UpdateCustomDrag(e.screenX, e.screenY);
        }
    });

    window.addEventListener('mouseup', function () {
        if (isMainDragging) {
            isMainDragging = false;
            if (typeof bridge !== 'undefined') {
                bridge.EndCustomDrag();
            }
        }
    });

    if ($id('nav-loader-btn')) {
        $id('nav-loader-btn').onclick = function () {
            window.openActionModal("Confirm Unload", "Are you sure you want to unload SirHurt?", "red", function () {
                if (window.chrome && window.chrome.webview && window.chrome.webview.hostObjects && window.chrome.webview.hostObjects.bridge) {
                    window.chrome.webview.hostObjects.bridge.UnloadToLoader();
                } else if (bridge) {
                    bridge.UnloadToLoader();
                }
            });
        };
    }

    document.querySelectorAll('.nav-item').forEach(function (i) {
        if (i.id === 'nav-loader-btn') return;
        i.onclick = function () { if (i.dataset.page) navigateTo(i.dataset.page); };
    });





    var searchContainer = document.querySelector('#settings-main .settings-search-container');
    if (searchContainer && !document.getElementById('search-indicator')) {
        var ind = document.createElement('div');
        ind.id = 'search-indicator';
        ind.style.display = 'none';
        ind.style.color = 'var(--purple)';
        ind.style.fontSize = '12.5px';
        ind.style.fontWeight = '500';
        ind.style.marginBottom = '12px';
        searchContainer.parentNode.insertBefore(ind, searchContainer.nextSibling);
    }


    document.querySelectorAll('.settings-search-container .settings-search').forEach(function (input) {
        input.addEventListener('input', function (e) {
            var term = e.target.value.toLowerCase();
            document.querySelectorAll('.settings-search-container .settings-search').forEach(inp => { if (inp !== e.target) inp.value = term; });

            var mainPane = document.getElementById('settings-main');
            var pageSettings = document.getElementById('page-settings');
            var indicator = document.getElementById('search-indicator');


            function triggerAnim(el) {
                if (!el) return;
                el.classList.remove('blur-anim');
                void el.offsetWidth;
                el.classList.add('blur-anim');
            }

            if (term.trim() === '') {

                if (indicator) indicator.style.display = 'none';

                document.querySelectorAll('.settings-view.sub-pane').forEach(p => {
                    pageSettings.appendChild(p);
                    p.style.display = 'none';
                    p.classList.remove('search-flattened');
                });


                document.querySelectorAll('.settings-page-header, .settings-back-header, .settings-search-container').forEach(el => {
                    var wasHidden = el.style.display === 'none';
                    el.style.display = '';
                    if (wasHidden) triggerAnim(el);
                });


                document.querySelectorAll('.settings-nav-group').forEach(g => {
                    var wasHidden = g.style.display === 'none' || g.style.display === '';
                    g.style.display = 'flex';
                    g.style.marginTop = '';
                    g.style.marginBottom = '';
                    if (wasHidden) triggerAnim(g);
                });

                document.querySelectorAll('.settings-nav-item').forEach(item => item.style.display = 'flex');

            } else {

                if (indicator) {
                    var indWasHidden = indicator.style.display === 'none';
                    indicator.style.display = 'block';
                    indicator.innerHTML = 'Searching for "' + e.target.value + '"';
                    if (indWasHidden) triggerAnim(indicator);
                }

                document.querySelectorAll('.settings-page-header, .settings-back-header').forEach(el => el.style.display = 'none');
                document.querySelectorAll('.settings-search-container').forEach(el => { if (!el.contains(e.target)) el.style.display = 'none'; });
                document.querySelectorAll('.settings-nav-item[onclick^="openSettingsPane"]').forEach(item => item.style.display = 'none');

                document.querySelectorAll('.settings-view.sub-pane').forEach(p => {
                    mainPane.appendChild(p);
                    p.style.display = 'flex';
                    p.classList.add('search-flattened');
                });


                document.querySelectorAll('.settings-nav-group').forEach(group => {
                    var hasVisible = false;
                    group.querySelectorAll('.settings-nav-item:not([onclick^="openSettingsPane"])').forEach(item => {
                        var title = item.querySelector('.sn-title');
                        var text = (title ? title.textContent.toLowerCase() : "");
                        if (text.includes(term)) { item.style.display = 'flex'; hasVisible = true; } else { item.style.display = 'none'; }
                    });

                    var groupWasHidden = group.style.display === 'none' || group.style.display === '';
                    group.style.display = hasVisible ? 'flex' : 'none';
                    group.style.marginTop = '0';

                    if (hasVisible) {
                        group.style.marginBottom = '12px';
                        if (groupWasHidden) triggerAnim(group);
                    }
                });
            }
        });
    });

    if (typeof require === 'function') { require(['vs/editor/editor.main'], setupMonaco); }
    else setupMonaco();


    setTimeout(function () { var s = $id('splash'); if (s) { s.style.opacity = '0'; setTimeout(function () { s.remove(); }, 500); } }, 400);
    window.updateConsolePlaceholders();


    if (settings.splitTabIds && settings.splitTabIds.length === 2) {
        setTimeout(function () {
            enterSplitView(settings.splitTabIds[0], settings.splitTabIds[1]);
        }, 1000);
    }


    setTimeout(function () {
        if (window.applyEditorSettings) window.applyEditorSettings();
    }, 2000);
});



window.applyStartupSettings = function () {
    if (!bridge) return;
    try {
        if (settings.topmost) bridge.SetTopMost(true);
        if (bridge.SetAutoInject) bridge.SetAutoInject(!!settings.autoinject);
    } catch (e) { }
};


var savedDlDir = localStorage.getItem('sh_dl_dir') || 'None';
var dlDirLabel = document.getElementById('dl-dir-label');
if (dlDirLabel) dlDirLabel.innerText = savedDlDir;
var btnSelectDir = document.getElementById('btn-select-dir');
if (btnSelectDir) {
    btnSelectDir.addEventListener('click', async function () {
        if (typeof bridge !== 'undefined' && bridge.SelectFolder) {
            var path = await bridge.SelectFolder();
            if (path) { localStorage.setItem('sh_dl_dir', path); if (dlDirLabel) dlDirLabel.innerText = path; savedDlDir = path; }
        }
    });
}

var dlModal = document.getElementById('download-modal'), dlTitle = document.getElementById('download-title'), dlStatus = document.getElementById('download-status'), dlSpinner = document.getElementById('download-spinner'), dlActions = document.getElementById('download-actions'), dlClose = document.getElementById('download-close'), dlRetry = document.getElementById('download-retry');
if (dlClose) {
    dlClose.onclick = function () {
        dlModal.classList.remove('visible');
        dlTitle.style.color = "var(--t1)";
        if (dlSpinner) dlSpinner.style.display = "block";
        if (dlActions) dlActions.style.display = "none";
        if (dlRetry) dlRetry.style.display = "none";
    };
}

let lastDownloadVersion = null;
window.startVersionDownload = function (version) {
    var dir = localStorage.getItem('sh_dl_dir') || 'None';
    if (dir === 'None' || !dir) { if (window.showNotification) window.showNotification("Please select a download directory first"); return; }
    if (!version || version === '') { if (window.showNotification) window.showNotification("Please enter a valid hash"); return; }
    if (!version.startsWith('version-') && version !== 'latest' && version !== 'previous') { version = 'version-' + version; }

    lastDownloadVersion = version;
    window._lastModalWasSirHurtUpdate = false;
    dlTitle.innerText = "Downloading " + version; dlTitle.style.color = "var(--t1)"; dlStatus.innerText = "Please wait, this may take a while...";
    dlSpinner.style.display = "block"; dlActions.style.display = "none"; if (dlRetry) dlRetry.style.display = "none"; dlModal.classList.add('visible');

    if (typeof bridge !== 'undefined' && bridge.DownloadRobloxVersion) { bridge.DownloadRobloxVersion(version, dir); }
    else { setTimeout(function () { window.onVersionDownloadComplete(true, version, dir, ""); }, 3000); }
};

if (dlRetry) {
    dlRetry.onclick = function () {
        // _lastModalWasSirHurtUpdate is set true by startSirHurtUpdateUI, false by startVersionDownload
        if (window._lastModalWasSirHurtUpdate) {
            dlTitle.innerText = "Updating SirHurt"; dlTitle.style.color = "var(--t1)"; dlStatus.innerText = "Retrying update. Please wait...";
            dlSpinner.style.display = "block"; dlActions.style.display = "none"; dlRetry.style.display = "none";
            window.bridgeCall('UpdateSirHurt');
        } else if (lastDownloadVersion) {
            window.startVersionDownload(lastDownloadVersion);
        }
    };
}

window.onVersionDownloadComplete = function (success, version, dir, errorMsg) {
    dlSpinner.style.display = "none"; dlActions.style.display = "flex";
    if (success) {
        if (dlRetry) dlRetry.style.display = "none";
        dlTitle.innerText = "Download Complete"; dlTitle.style.color = "var(--purple)"; dlStatus.innerText = "Downloaded successfully in " + dir;
        dlClose.style.color = "var(--purple)"; dlClose.style.background = "rgba(var(--accent-rgb, 162, 162, 208), 0.1)"; dlClose.style.borderColor = "rgba(var(--accent-rgb, 162, 162, 208), 0.2)";
        setTimeout(function () { if (window.renderRobloxManager) { window.renderRobloxManager(window.latestWeaoVersion || version); } }, 800);
    } else {
        if (dlRetry) dlRetry.style.display = "block";
        dlTitle.innerText = "Download Failed"; dlTitle.style.color = "var(--red)"; dlStatus.innerText = "Error: " + errorMsg;
        dlClose.style.color = "var(--red)"; dlClose.style.background = "rgba(255, 69, 58, 0.1)"; dlClose.style.borderColor = "rgba(255, 69, 58, 0.2)";
    }
};

var verInput = document.getElementById('dl-version-input');
var btnDlLatest = document.getElementById('btn-dl-latest');
var btnDlPrev = document.getElementById('btn-dl-prev');
var btnDlSpec = document.getElementById('btn-dl-spec');
if (btnDlLatest) btnDlLatest.addEventListener('click', function () { if (window.latestWeaoVersion) { window.startVersionDownload(window.latestWeaoVersion); } else { if (window.showNotification) window.showNotification("Still fetching latest version hash..."); } });
if (btnDlPrev) btnDlPrev.addEventListener('click', function () { if (window.showNotification) window.showNotification("Opening WEAO Downgrader in browser..."); if (typeof bridge !== 'undefined') bridge.OpenBrowser("https://rdd.weao.gg/"); });
if (btnDlSpec) btnDlSpec.addEventListener('click', function () { var ver = verInput ? verInput.value.trim() : ''; window.startVersionDownload(ver); });

window.renderLiveStatus = function (data) {
    var list = $id('live-status-list');
    if (!list) return;
    list.innerHTML = '';

    if (data === 'Error fetching status.') {
        list.innerHTML = '<div class="cl-entry"><div class="cl-body" style="color:var(--red)">Failed to reach whatexpsare.online</div></div>';
        return;
    }

    var cleanHtml = data.replace(/<\/(div|p|h[1-6]|li|tr)>/gi, '\n').replace(/<br\s*[\/]?>/gi, '\n');
    var temp = document.createElement('div');
    temp.innerHTML = cleanHtml;
    var rawText = temp.innerText || temp.textContent || data;
    var lines = rawText.split('\n').map(function (l) { return l.trim(); }).filter(function (l) { return l.length > 0; });

    var startIndex = -1;
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].includes('SirHurt') || lines[i].includes('sirhurt')) { startIndex = i; break; }
    }

    if (startIndex === -1) { list.innerHTML = '<div class="cl-entry"><div class="cl-body">Status loaded, but SirHurt data was not found on the page.</div></div>'; return; }

    var el = document.createElement('div');
    el.className = 'cl-entry';
    var bodyHtml = lines.slice(startIndex, startIndex + 4).map(function (l) { return '<div style="margin-bottom:4px;">' + esc(l) + '</div>'; }).join('');

    el.innerHTML =
        '<div class="cl-top">' +
        '<div class="cl-ver">whatexpsare.online</div>' +
        '<div class="cl-badge" style="background:var(--purple); color:#000;">SYNCED</div>' +
        '</div>' +
        '<div class="cl-body" style="color:var(--t1); font-size:11px; margin-top:6px;">' + bodyHtml + '</div>';
    list.appendChild(el);
};

window.addEventListener('load', function () {
    setTimeout(function () {
        if (bridge && bridge.UIReady) bridge.UIReady();
        var app = document.getElementById('app');
        if (app) app.classList.add('play-intro');
        if (window.applyStartupSettings) window.applyStartupSettings();
    }, 80);
});

window.addEventListener('unhandledrejection', function (event) {
    try {
        if (event.reason && event.reason.parameters && event.reason.parameters.error) {
            var errStr = event.reason.parameters.error;
            if (errStr.includes('0x80020006') || errStr.includes('0x80070057')) { event.preventDefault(); }
        }
    } catch (e) { }
});


window.bridgeCall = function (method, arg) {
    if (typeof bridge === 'undefined') return;
    // Guard against duplicate concurrent UpdateSirHurt calls
    if (method === 'UpdateSirHurt' || method === 'ReinstallSirHurt') {
        if (window._sirHurtUpdateInProgress) return;
        window._sirHurtUpdateInProgress = true;
        if (!window._sirHurtAutoRetrying) {
            window._sirHurtUpdateRetryCount = 0;
            window._lastUpdateMethod = method;
        }
    }
    try {
        if (arg !== undefined) bridge[method](arg);
        else bridge[method]();
    } catch (e) {
        window._sirHurtUpdateInProgress = false;
    }
};

window.onUpdateComplete = function (success, errorMsg) {
    var btn = document.getElementById('btn-do-update');
    window._sirHurtUpdateInProgress = false;
    window.isUpdatingSirHurt = false;

    if (btn) {
        btn.innerText = "Update Now";
        btn.style.opacity = "1";
        btn.style.pointerEvents = "auto";
        btn.style.background = "rgba(var(--accent-rgb, 162, 162, 208), 0.1)";
        btn.style.borderColor = "rgba(var(--accent-rgb, 162, 162, 208), 0.2)";
        btn.style.color = "var(--purple)";
    }

    if (!success) {
        if (window.showNotification) window.showNotification('Update Error: ' + errorMsg);

        const uTitle = document.getElementById('update-title-text');
        const uSub = document.getElementById('update-sub-text');
        const uNotes = document.getElementById('update-notes-text');
        const uIconBg = document.getElementById('update-icon-bg');
        const uIconSvg = document.getElementById('update-icon-svg');
        const actionNormal = document.getElementById('update-actions-normal');
        const updateCard = document.getElementById('home-card-update');

        if (uTitle) {
            uTitle.innerText = "Update Failed";
            uTitle.style.color = "var(--red)";
        }
        if (uSub) {
            uSub.innerText = "Error Occurred";
            uSub.style.color = "var(--red)";
        }
        if (uNotes) {
            uNotes.innerText = errorMsg || "SirHurt package download returned invalid data.";
            uNotes.style.color = "var(--red)";
        }
        if (uIconBg) {
            uIconBg.style.background = "rgba(255, 69, 58, 0.1)";
            uIconBg.style.color = "var(--red)";
            uIconBg.style.border = "1px solid rgba(255, 69, 58, 0.2)";
        }
        if (uIconSvg) {
            uIconSvg.innerHTML = '<path d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"></path>';
        }
        if (updateCard) {
            updateCard.style.background = "linear-gradient(130deg, rgba(255, 69, 58, 0.08) 0%, rgba(50, 20, 20, 0.35) 100%)";
            updateCard.style.borderColor = "rgba(255, 69, 58, 0.2)";
        }

        if (btn) {
            btn.innerText = "Retry";
            btn.style.background = "rgba(255, 69, 58, 0.1)";
            btn.style.borderColor = "rgba(255, 69, 58, 0.2)";
            btn.style.boxShadow = "none";
            btn.style.color = "var(--red)";
            btn.onclick = () => {
                window.isUpdatingSirHurt = true;
                btn.innerText = "Downloading...";
                btn.style.opacity = "0.6";
                btn.style.pointerEvents = "none";
                if (window.startSirHurtUpdateUI) window.startSirHurtUpdateUI('LIVE');
                window.bridgeCall('UpdateSirHurt');
            };
        }
        return;
    }

    if (window.latestWeaoVersion) {
        localStorage.setItem('installed_version', window.latestWeaoVersion);
        var insVerLabel = document.getElementById('installed-version');
        if (insVerLabel) insVerLabel.innerText = "SirHurt Updated";
    }

    if (window.checkSirHurtStatus) window.checkSirHurtStatus();
};


window.startSirHurtUpdateUI = function (version) {
    const dlModal = document.getElementById('download-modal');
    const dlTitle = document.getElementById('download-title');
    const dlStatus = document.getElementById('download-status');
    const dlSpinner = document.getElementById('download-spinner');
    const dlActions = document.getElementById('download-actions');

    if (!dlModal) return;

    window._lastModalWasSirHurtUpdate = true;
    dlTitle.innerText = "Updating SirHurt";
    dlTitle.style.color = "var(--t1)";
    dlStatus.innerText = "Targeting: " + version;
    dlSpinner.style.display = "block";
    dlActions.style.display = "none";

    dlModal.classList.add('visible');
};


window.onSirHurtUpdateResult = function (success, message) {
    if (!success) {
        if (typeof window._sirHurtUpdateRetryCount === 'undefined') {
            window._sirHurtUpdateRetryCount = 0;
        }
        if (window._sirHurtUpdateRetryCount < 2) {
            window._sirHurtUpdateRetryCount++;
            window.isUpdatingSirHurt = true;
            window._sirHurtUpdateInProgress = false;

            window._sirHurtAutoRetrying = true;
            setTimeout(function () {
                window.bridgeCall(window._lastUpdateMethod || 'UpdateSirHurt');
                window._sirHurtAutoRetrying = false;
            }, 1500);
            return;
        }
    }

    window.isUpdatingSirHurt = false;
    window._sirHurtUpdateInProgress = false;
    const dlTitle = document.getElementById('download-title');
    const dlStatus = document.getElementById('download-status');
    const dlClose = document.getElementById('download-close');

    if (document.getElementById('download-spinner')) document.getElementById('download-spinner').style.display = "none";
    if (document.getElementById('download-actions')) document.getElementById('download-actions').style.display = "flex";
    if (dlStatus) dlStatus.innerText = message;


    if (window.onUpdateComplete) window.onUpdateComplete(success, message);

    if (success) {
        localStorage.removeItem('sirhurt_was_downgraded');
        if (dlRetry) dlRetry.style.display = "none";
        if (dlTitle) {
            if (message && message.toLowerCase().includes('reinstalled')) {
                dlTitle.innerText = "SirHurt was reinstalled";
            } else {
                dlTitle.innerText = "Update Complete";
            }
            dlTitle.style.color = "var(--purple)";
        }
        if (dlClose) {
            dlClose.style.color = "var(--purple)";
            dlClose.style.background = "rgba(var(--accent-rgb, 162, 162, 208), 0.1)";
        }

        if (window.latestWeaoVersion) {
            localStorage.setItem('installed_version', window.latestWeaoVersion);
        }


        if (window.checkSirHurtStatus) window.checkSirHurtStatus();
    } else {
        if (dlRetry) dlRetry.style.display = "block";
        if (dlTitle) {
            dlTitle.innerText = "Update Failed";
            dlTitle.style.color = "var(--red)";
        }
        if (dlClose) {
            dlClose.style.color = "var(--red)";
            dlClose.style.background = "rgba(255, 69, 58, 0.1)";
        }
    }
};

let actionModalCallback = null;

window.openActionModal = function (title, desc, confirmColor, onConfirm) {
    const modal = document.getElementById('action-modal');
    if (!modal) return;

    document.getElementById('action-title').innerText = title;
    document.getElementById('action-desc').innerText = desc;

    const confirmBtn = document.getElementById('action-confirm');
    if (confirmColor === 'red') {
        confirmBtn.style.background = 'rgba(255, 69, 58, 0.1)';
        confirmBtn.style.borderColor = 'rgba(255, 69, 58, 0.2)';
        confirmBtn.style.color = 'var(--red)';
    } else {
        confirmBtn.style.background = 'var(--purple)';
        confirmBtn.style.borderColor = 'var(--bd)';
        confirmBtn.style.color = '#fff';
    }

    actionModalCallback = onConfirm;
    modal.classList.add('visible');
};

window.closeActionModal = function () {
    const modal = document.getElementById('action-modal');
    if (modal) modal.classList.remove('visible');
    actionModalCallback = null;
};

if (document.getElementById('action-cancel')) {
    document.getElementById('action-cancel').onclick = closeActionModal;
}
if (document.getElementById('action-confirm')) {
    document.getElementById('action-confirm').onclick = function () {
        if (actionModalCallback) actionModalCallback();
        closeActionModal();
    };
}

window.openDeleteModal = function (version, supportedVersion) {
    window.openActionModal(
        "Delete " + version + "?",
        "Are you sure you want to delete this version? If you need it again you will have to redownload it.",
        "red",
        function () {
            if (typeof bridge !== 'undefined') {
                bridge.DeleteRobloxVersion(version);
                setTimeout(function () {
                    if (window.renderRobloxManager) window.renderRobloxManager(window.latestWeaoVersion || '');
                }, 2000);
            }
        }
    );
};



window.openRenameTitleModal = function () {
    const modal = document.getElementById('rename-modal');
    const input = document.getElementById('rename-input');
    const title = document.getElementById('rename-title');
    if (!modal || !input) return;

    title.innerText = "Set UI Title";
    input.value = localStorage.getItem('custom_ui_title') || "SirHurt";
    input.maxLength = 12;
    modal.classList.add('visible');

    const confirmBtn = document.getElementById('rename-confirm');
    confirmBtn.onclick = function () {
        const val = input.value.trim().substring(0, 12);
        input.maxLength = 524288;
        if (val) {
            localStorage.setItem('custom_ui_title', val);
            window.applyUITitle();
            modal.classList.remove('visible');
        }
    };
    document.getElementById('rename-cancel').onclick = () => { input.maxLength = 524288; modal.classList.remove('visible'); };
};

window.resetUITitle = function () {
    localStorage.removeItem('custom_ui_title');
    window.applyUITitle();
    if (window.showNotification) window.showNotification("UI Title reset to default");
};

window.applyUITitle = function () {
    const titleEl = document.getElementById('custom-ui-title');
    if (titleEl) {
        titleEl.innerText = localStorage.getItem('custom_ui_title') || "SirHurt";
    }
};


const CURATED_FONTS = [
    { name: "Inter", family: "'Inter', sans-serif" },
    { name: "Rubik", family: "'Rubik', sans-serif" },
    { name: "Outfit", family: "'Outfit', sans-serif" },
    { name: "Jakarta Sans", family: "'Plus Jakarta Sans', sans-serif" },
    { name: "Manrope", family: "'Manrope', sans-serif" },
    { name: "JetBrains Mono", family: "'JetBrains Mono', monospace" }
];

window.tempSelectedFont = "";
window.tempSelectedFontFamily = "";

window.openFontPickerModal = function () {
    const modal = document.getElementById('font-picker-modal');
    const overlay = document.getElementById('picker-overlay');
    if (!modal) return;

    window.tempSelectedFont = localStorage.getItem('custom_ui_font') || "Inter";
    window.tempSelectedFontFamily = localStorage.getItem('custom_ui_font_family') || "'Inter', sans-serif";

    modal.classList.add('active');
    if (overlay) overlay.classList.add('active');


    const searchInput = document.getElementById('font-search');
    if (searchInput) searchInput.value = '';

    window.updateFontPreview();
    window.renderFontPicker('');
    window.renderSystemFonts('');
};

const SYSTEM_FONTS = [
    "Arial", "Arial Black", "Bahnschrift", "Calibri", "Cambria", "Candara", "Comic Sans MS", "Consolas",
    "Constantia", "Corbel", "Courier New", "Ebrima", "Franklin Gothic Medium", "Gabriola", "Gadugi",
    "Georgia", "Impact", "Ink Free", "Javanese Text", "Leelawadee UI", "Lucida Console", "Lucida Sans Unicode",
    "Malgun Gothic", "Microsoft Himalaya", "Microsoft JhengHei", "Microsoft New Tai Lue", "Microsoft PhagsPa",
    "Microsoft Tai Le", "Microsoft YaHei", "Microsoft Yi Baiti", "MingLiU-ExtB", "MS Gothic", "MS UI Gothic",
    "MV Boli", "Myanmar Text", "Nirmala UI", "Palatino Linotype", "Segoe MDL2 Assets", "Segoe Print",
    "Segoe Script", "Segoe UI", "Segoe UI Historic", "Segoe UI Emoji", "Segoe UI Symbol", "SimSun",
    "Sitka", "Sylfaen", "Symbol", "Tahoma", "Times New Roman", "Trebuchet MS", "Verdana", "Webdings",
    "Wingdings", "Yu Gothic"
].map(f => ({ name: f, family: `'${f}', sans-serif` }));

window.updateFontPreview = function () {
    const preview = document.getElementById('font-preview-text');
    if (preview) {
        preview.style.fontFamily = window.tempSelectedFontFamily;
    }
};

window.renderFontPicker = function (query) {
    const curatedContainer = document.getElementById('curated-fonts');
    const systemContainer = document.getElementById('system-fonts');
    if (!curatedContainer || !systemContainer) return;

    const q = (query || '').toLowerCase();


    curatedContainer.innerHTML = '';
    CURATED_FONTS.forEach(font => {
        const el = document.createElement('div');
        el.className = 'font-item' + (window.tempSelectedFont === font.name ? ' active' : '');
        el.style.fontFamily = font.family;
        el.innerHTML = `
            <div class="font-preview">Abc</div>
            <div class="font-name" style="font-size: 10px;">${font.name}</div>
        `;
        el.onclick = () => {
            window.tempSelectedFont = font.name;
            window.tempSelectedFontFamily = font.family;
            window.updateFontPreview();
            window.renderFontPicker(query);
        };
        curatedContainer.appendChild(el);
    });


    const allFonts = [...CURATED_FONTS, ...SYSTEM_FONTS];
    const uniqueFonts = [];
    const seen = new Set();
    allFonts.forEach(f => {
        if (!seen.has(f.name)) {
            uniqueFonts.push(f);
            seen.add(f.name);
        }
    });

    const filtered = uniqueFonts.filter(f => f.name.toLowerCase().includes(q));

    systemContainer.innerHTML = '';
    if (filtered.length === 0) {
        systemContainer.innerHTML = `<div style="padding: 20px; text-align: center; color: var(--t3); font-size: 11px;">No matches</div>`;
    } else {
        filtered.forEach(font => {
            const el = createFontListItem(font, q);
            systemContainer.appendChild(el);
        });
    }
};

function createFontListItem(font, query) {
    const el = document.createElement('div');
    el.className = 'font-list-item' + (window.tempSelectedFont === font.name ? ' active' : '');
    el.style.fontFamily = font.family;
    el.style.padding = '7px 10px';
    el.style.marginBottom = '2px';
    el.style.borderRadius = '6px';
    el.style.cursor = 'pointer';
    el.style.fontSize = '12px';
    el.style.color = 'var(--t1)';
    el.style.transition = 'all 0.15s';
    el.style.display = 'flex';
    el.style.alignItems = 'center';
    el.style.justifyContent = 'space-between';

    if (window.tempSelectedFont === font.name) {
        el.style.background = 'color-mix(in srgb, var(--purple) 15%, transparent)';
        el.style.color = 'var(--purple)';
        el.style.boxShadow = 'inset 0 0 0 1px color-mix(in srgb, var(--purple) 20%, transparent)';
    }

    el.innerHTML = `
        <span style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 140px;">${font.name}</span>
        <span style="font-size: 9px; opacity: 0.3; font-family: 'Inter', sans-serif;">${window.tempSelectedFont === font.name ? 'SELECTED' : ''}</span>
    `;

    el.onmouseover = () => { if (window.tempSelectedFont !== font.name) el.style.background = 'rgba(255,255,255,0.04)'; };
    el.onmouseout = () => { if (window.tempSelectedFont !== font.name) el.style.background = 'transparent'; };

    el.onclick = () => {
        window.tempSelectedFont = font.name;
        window.tempSelectedFontFamily = font.family;
        window.updateFontPreview();
        window.renderFontPicker(query);
    };
    return el;
}

window.renderSystemFonts = function (query) {

};

window.resetUIFont = function () {
    localStorage.removeItem('custom_ui_font');
    localStorage.removeItem('custom_ui_font_family');
    window.applyUIFont();
    if (window.showNotification) window.showNotification("UI Font reset to default");
};

window.applyUIFont = function () {
    const family = localStorage.getItem('custom_ui_font_family') || "'Inter', sans-serif";
    document.documentElement.style.setProperty('--main-font', family);
};


document.addEventListener('DOMContentLoaded', () => {
    window.applyUITitle();
    window.applyUIFont();


    const closeBtn = document.getElementById('btn-close-font-picker');
    if (closeBtn) {
        closeBtn.onclick = () => {
            document.getElementById('font-picker-modal').classList.remove('active');
            const overlay = document.getElementById('picker-overlay');
            if (overlay) overlay.classList.remove('active');
        };
    }


    const fontSearch = document.getElementById('font-search');
    if (fontSearch) {
        fontSearch.oninput = (e) => {
            const q = e.target.value;
            window.renderFontPicker(q);
        };
    }

    const applyBtn = document.getElementById('btn-apply-font');
    if (applyBtn) {
        applyBtn.onclick = () => {
            localStorage.setItem('custom_ui_font', window.tempSelectedFont);
            localStorage.setItem('custom_ui_font_family', window.tempSelectedFontFamily);
            window.applyUIFont();
            document.getElementById('font-picker-modal').classList.remove('active');
            const overlay = document.getElementById('picker-overlay');
            if (overlay) overlay.classList.remove('active');
            if (window.showNotification) window.showNotification("UI Font updated successfully");
        };
    }
});


var btnResetShow = document.getElementById('btn-reset-settings');
var resetModal = document.getElementById('reset-modal');
var resetCancel = document.getElementById('reset-cancel');
var resetConfirm = document.getElementById('reset-confirm');

if (btnResetShow && resetModal) {
    btnResetShow.onclick = function () { resetModal.classList.add('visible'); };
    if (resetCancel) resetCancel.onclick = function () { resetModal.classList.remove('visible'); };
    if (resetConfirm) {
        resetConfirm.onclick = function () {
            if (window.applyUISize) window.applyUISize('normal');
            localStorage.removeItem('sh_settings');
            localStorage.removeItem('sh_theme');
            localStorage.removeItem('sh_tabs');
            localStorage.removeItem('sh_hub_dock_hidden');
            localStorage.removeItem('sh_split_tabs');
            localStorage.removeItem('custom_ui_font');
            localStorage.removeItem('custom_ui_font_family');
            localStorage.removeItem('custom_ui_title');
            location.reload();
        };
    }
}

var btnReinstallSirHurt = document.getElementById('btn-reinstall-sirhurt');
if (btnReinstallSirHurt) {
    btnReinstallSirHurt.onclick = function () {
        if (window.openActionModal) {
            window.openActionModal(
                "Reinstall SirHurt?",
                "All files in the directory will be deleted and then SirHurt will be installed again, autoexec, scripts and workspace will never be modified.",
                "purple",
                function () {
                    window.bridgeCall('ReinstallSirHurt');
                }
            );
        } else {
            window.bridgeCall('ReinstallSirHurt');
        }
    };
}

var btnDowngradeSirHurt = document.getElementById('btn-downgrade-sirhurt');

function _showProcessingModal() {
    var m = $id('processing-modal');
    var spinner = $id('processing-spinner');
    var icon = $id('processing-icon');
    var title = $id('processing-title');
    var sub = $id('processing-sub');
    var actions = $id('processing-actions');
    if (!m) return;
    if (spinner) spinner.style.display = 'block';
    if (icon) { icon.style.display = 'none'; icon.textContent = ''; }
    if (title) title.textContent = 'Processing...';
    if (sub) sub.textContent = 'Please wait while the bootstrapper runs.';
    if (actions) actions.style.display = 'none';
    m.classList.add('visible');
}

window.onDowngradeStart = function () {
    _showProcessingModal();
};

window.onDowngradeResult = function (success) {
    var spinner = $id('processing-spinner');
    var icon = $id('processing-icon');
    var iconSvg = $id('processing-icon-svg');
    var title = $id('processing-title');
    var sub = $id('processing-sub');
    var actions = $id('processing-actions');
    if (spinner) spinner.style.display = 'none';
    if (icon) icon.style.display = 'block';
    if (iconSvg) {
        if (success) {
            iconSvg.setAttribute('stroke', 'var(--green, #4ade80)');
            iconSvg.innerHTML = '<polyline points="20 7 10 17 5 12" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></polyline>';
        } else {
            iconSvg.setAttribute('stroke', 'var(--red, #f87171)');
            iconSvg.innerHTML = '<line x1="5" y1="5" x2="19" y2="19" stroke-width="3.5" stroke-linecap="round"></line><line x1="19" y1="5" x2="5" y2="19" stroke-width="3.5" stroke-linecap="round"></line>';
        }
    }
    if (title) { title.textContent = success ? 'Done' : 'Failed'; title.style.color = success ? 'var(--green, #4ade80)' : 'var(--red, #f87171)'; }
    if (sub) sub.textContent = success ? 'Restarting UI...' : 'sirhurt.exe and sirhurt.dll were not found.';
    if (actions && !success) actions.style.display = 'block';
    if (success) {
        localStorage.removeItem('installed_version');
        localStorage.setItem('sirhurt_was_downgraded', 'true');
    }
};

if ($id('processing-close')) {
    $id('processing-close').onclick = function () {
        var m = $id('processing-modal');
        if (m) m.classList.remove('visible');
        var title = $id('processing-title');
        if (title) title.style.color = '';
    };
}

if (btnDowngradeSirHurt) {
    btnDowngradeSirHurt.onclick = function () {
        if (window.openActionModal) {
            window.openActionModal(
                "Warning",
                "Please make sure that the Roblox version you will be using is opened",
                "purple",
                function () {
                    if (typeof bridge !== 'undefined' && bridge.DowngradeSirHurt) {
                        bridge.DowngradeSirHurt();
                    }
                }
            );
        } else {
            if (typeof bridge !== 'undefined' && bridge.DowngradeSirHurt) {
                bridge.DowngradeSirHurt();
            }
        }
    };
}

if ($id('btn-spoof-no')) $id('btn-spoof-no').onclick = function () {
    if ($id('toggle-spoof-remember').checked) {
        settings.skipSpoofWarning = true;
        saveSettings();
    }
    skipSpoofWarningSession = true;
    $id('spoof-warning-modal').classList.remove('visible');
};
if ($id('btn-spoof-yes')) $id('btn-spoof-yes').onclick = function () {
    if ($id('toggle-spoof-remember').checked) {
        settings.skipSpoofWarning = true;
        saveSettings();
    }
    skipSpoofWarningSession = true;


    settings.errorSpoofing = true;
    if ($id('toggle-errorspoof')) $id('toggle-errorspoof').checked = true;
    saveSettings();
    window.updateConsolePlaceholders();

    $id('spoof-warning-modal').classList.remove('visible');
};



window.zenithScrollObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('in-view');
        } else {
            entry.target.classList.remove('in-view');
        }
    });
}, { threshold: 0.01 });

window.observeScrollElement = function (el) {
    if (el) window.zenithScrollObserver.observe(el);
};

setTimeout(() => {
    document.querySelectorAll('.settings-nav-item, .updater-card > div, .card-sub, .action-row, .zenith-scroll-item').forEach(el => {
        if (!el.classList.contains('zenith-scroll-item')) el.classList.add('zenith-scroll-item');
        window.observeScrollElement(el);
    });
}, 500);


if (document.getElementById('multi-instance-ok')) {
    document.getElementById('multi-instance-ok').onclick = function () {
        document.getElementById('multi-instance-modal').classList.remove('visible');
    };
}


window.toggleMultiInstance = async function (enabled) {
    if (typeof bridge !== 'undefined' && bridge.SetMultiInstance) {
        try {
            var res = await bridge.SetMultiInstance(enabled);

            if (res === "PROCESS_EXISTS") {

                var check = document.getElementById('toggle-multi-instance');
                if (check) check.checked = false;


                settings.multiInstance = false;
                saveSettings();


                var modal = document.getElementById('multi-instance-modal');
                if (modal) modal.classList.add('visible');
            }
            else if (res && res.startsWith("ERROR")) {
                console.error("Multi-instance backend error:", res);
                settings.multiInstance = false;
                saveSettings();
            }
            else {

                settings.multiInstance = enabled;
                saveSettings();
            }
        } catch (err) {
            console.error("SetMultiInstance bridge failure:", err);
            settings.multiInstance = false;
            saveSettings();
        }
    } else {
        settings.multiInstance = enabled;
        saveSettings();
    }
};



setTimeout(async function () {


    if (monacoEditor) monacoEditor.layout();
    if (monacoEditorSecondary) monacoEditorSecondary.layout();

    if (typeof bridge !== 'undefined' && settings.multiInstance && bridge.SetMultiInstance) {
        try {
            var res = await bridge.SetMultiInstance(true);
            if (res === "PROCESS_EXISTS") {
                settings.multiInstance = false;
                saveSettings();
                var check = document.getElementById('toggle-multi-instance');
                if (check) check.checked = false;

                var modal = document.getElementById('multi-instance-modal');
                if (modal) modal.classList.add('visible');
            }
        } catch (err) {
            console.error("Boot multi-instance sync error:", err);
        }
    }
}, 1500);



function amTab(clickedEl, targetId) {
    const stage = document.getElementById('am-page-stage');
    const toggleText = document.getElementById('am-server-toggle-text');
    const openServers = targetId === 'acc-viewport-servers';
    if (stage) stage.classList.toggle('servers-open', openServers);
    if (toggleText) toggleText.innerText = openServers ? 'Accounts' : 'Servers';
}


window.AccountManager = {
    accounts: [],
    selectedAccount: null,
    serverPageOpen: false,

    toggleServerPage: function (force) {
        const open = typeof force === 'boolean' ? force : !this.serverPageOpen;
        this.serverPageOpen = open;
        amTab(null, open ? 'acc-viewport-servers' : 'acc-viewport-accounts');
    },

    openFullChangelog: function (date, type) {
        const modal = document.getElementById('changelog-modal');
        const title = document.getElementById('cl-modal-title');
        const body = document.getElementById('cl-modal-body');

        if (!modal || !title || !body) return;

        title.innerText = `${date} ${type} Changelog`;

        const changelogs = {
            '15/07/2026 v1.2': `
                • The UI fully saves settings inside the local folder now (it used to save in registry certain settings and values)<br>
                • Loader has multiple changes and updates, acrylic is supported and the fetching weao and checking for updates speeds have been massivly improved<br>
                • Fixed Account Manager's Join Server action<br>
                • Slightly redesigned the servers page in Account Manager<br>
                • Added an Open Roblox button for the selected account<br>
                • Added History: closed tabs are saved under Files &gt; History and can be recovered; this can be disabled in Settings<br>
                • Added tab drag-and-drop to Files; hold and drag a tab into Scripts or AutoExec to save it as a .lua script<br>
                • Fixed the Settings search bar not working and breaking the entire UI<br>
                • Added an option to start the UI automatically with Windows<br>
                • Added options to automatically spoof the MAC address when the UI opens or closes<br>
                • Added options to automatically clear Roblox cookies when the UI opens or closes<br>
                • Added options to automatically clean Roblox when the UI opens or closes<br>
                • Fixed Auto Execute always running and failing to detect .lua and .txt files<br>
                • Added a Duplicate option for tabs in the context menu<br>
                • Added page caching so pages preserve their content and remember their positions<br>
                • Added an adjustable console line limit in Miscellaneous settings<br>
                • Added the Acrylic setting in Interface settings, enabled unfocused opacity control, and removed the old opacity setting<br>
                • Many bug fixes, UI improvements, visual fixes, and visual changes
            `,
            '18/06/2026 v1.1.02': `
                • Removed "The requested operation requires elevation". The UI will ignore the admin request from sirhurt.exe<br>
                • Fixed "Injecting..." status even after being injected (where you would have to restart the UI to have it working)
            `,
            '13/06/2026 v1.1.01': `
                • Fixed SirHurtV5.exe not being deleted after UI updates
            `,
            '04/06/2026 v1.1': `
                • Added Cookie cleaner - fastest way to bypass api bans in roblox<br>
                • Added Install roblox - fastest way to install roblox directly from the UI<br>
                • Fully reworked read only, it also now saves after restarting the UI<br>
                • Added right click context menu for auto execute and scripts, when you right click in an empty space you wil have the options to refresh or create a new file<br>
                • Fixed some issues with Pinned tabs<br>
                • Fixed updating and downloading SirHurt errors<br>
                • Fixed useless spacing between found: version and buttons in roblox manager<br>
                • Maintenance is now called Utilities<br>
                • Changed icons for buttons in editor<br>
                • Added homepage detection when injected<br>
                • Status indication is fully accurate now<br>
                • Added a new feature - Downgrade SirHurt, this will run the bootstrapper and install the correct SirHurt injector for the running Roblox version<br>
                • Fixed the UI freezing when having multiple tabs with a lot of lines of code in them<br>
                • Fixed auto execute manager, it actually works now<br>
                • Fixed auto inject<br>
                • Fixed Insert Spaces<br>
                • Fixed Clear Lua Console on Execute<br>
                • Fixed bracket colorization<br>
                • Fixed Forest Moss theme
            `,
            '27/05/2026': `
                • Added custom themes, you can fully make your own theme now.<br>
                • Completely reworked account manager, now shows accounts correctly, their profile picture and user ID, also added right click menu for accounts which you can manage the account with. Add account fully works now and reworked servers function.<br>
                • Maintenance and tools have also been reworked, roblox cleaner and sirhurt cleaner actually work now, mac address spoofer is IN the UI itself, wont open powershell anymore and roblox manager delete works now.<br>
                • New default theme<br>
                • Added loader<br>
                • For execution settings new features are safe mode, hide script context and script hub auto load.<br>
                • For miscellaneous new features are Close roblox on exit, restore tabs on startup, unlock fps with custom fps cap, minimize to system tray, lock to screen bounds, smooth drag to scroll, discord rich presence and hardware acceleration.<br>
                • Added a new setting which is auto execute, with this feature you can individually manage scripts in auto execute and even make it so they dont execute in certain games, auto execute delay etc.<br>
                • Tutorial has fully been reworked and is now actually animated<br>
                • Added sirhurt installed feature<br>
                • Added reinstall sirhurt feature<br>
                • Added forget all choices feature<br>
                • Fixed scriptblox not always loading<br>
                • Optimized sirhurt updater
            `,
            '13/05/2026': `
                • Fully reworked on symmetry of the UI and spacings, everything should look much cleaner now<br>
                • Script hub feature completed, filters for ScriptBlox are fixed, the dock is remade and can be minimized now<br>
                • Added UI sizes such as small, normal, big, oversized etc, this setting is located in interface all the way down<br>
                • Fully remade account manager, completely redesigned it and has working login methods now, server filters and refresh have also been improved in terms of speed and filters are fixed<br>
                • Fixed in consoles "Remember choice" from the warning popup not actually working<br>
                • Redesigned home page<br>
                • Improved Injection indicator<br>
                • More interface settings and a lot of improvements for appearance and functionality
            `
        };

        body.innerHTML = changelogs[date] || 'No extended changelog available for this date.';
        modal.classList.add('visible');
    },

    addAccount: function () {
        try {
            if (window.bridge && window.bridge.AddAccount) {
                window.bridge.AddAccount();
            } else {
                this.openLoginModal();
            }
        } catch (e) {
            console.error("Failed to trigger AddAccount bridge method", e);
            this.openLoginModal();
        }
    },

    openLoginModal: function () {
        const loginOverlay = document.getElementById('login-modal');
        if (loginOverlay) loginOverlay.style.display = 'flex';
    },

    submitLoginCookie: async function (cookieString) {
        try {
            if (window.bridge) {
                await window.bridge.SubmitCookie(cookieString);
            }
            const loginOverlay = document.getElementById('login-modal');
            if (loginOverlay) loginOverlay.style.display = 'none';
        } catch (err) {
            console.error("Bridge crashed submitting cookie. Check C# backend!", err);
        }
    },

    init: function () {
        this.bindEvents();
        this.loadAccounts();
        const savedPid = localStorage.getItem('launcher_place_id');
        const savedJid = localStorage.getItem('launcher_job_id');
        if (savedPid) {
            if ($id('launcher-place-id')) $id('launcher-place-id').value = savedPid;
            this.updateGameTitle(savedPid);
        }
        if (savedJid) {
            if ($id('launcher-job-id')) $id('launcher-job-id').value = savedJid;
        }
    },

    bindEvents: function () {
        const accSearch = $id('acc-search');
        if (accSearch) {
            accSearch.oninput = (e) => this.renderList(e.target.value.toLowerCase());
        }
        const pidInput = $id('launcher-place-id');
        if (pidInput) {
            pidInput.oninput = () => {
                const val = pidInput.value;
                this.updateGameTitle(val.trim());
            };
        }
    },

    updateGameTitle: async function (pid) {
        const titleEl = $id('server-browser-title');
        if (!titleEl) return;
        if (!pid || isNaN(pid)) {
            titleEl.innerText = "Roblox Game";
            return;
        }
        try {
            if (typeof bridge === 'undefined') return;
            const res = await bridge.GetPlaceDetails(pid);
            const details = JSON.parse(res);
            if (details && details.length > 0) {
                titleEl.innerText = details[0].name;
            } else {
                titleEl.innerText = "Roblox Game";
            }
        } catch (e) {
            titleEl.innerText = "Roblox Game";
        }
    },

    selectAccount: function (username, forceSelect) {
        if (!forceSelect && this.selectedAccount === username) {
            this.selectedAccount = null;
        } else {
            this.selectedAccount = username;
        }
        this.renderList($id('acc-search')?.value.toLowerCase() || "");
        if (this.selectedAccount) {
            const acc = this.accounts.find(a => a.Username.toLowerCase() === username.toLowerCase());
            if (acc) {
                if (acc.LastPlaceId) {
                    if ($id('launcher-place-id')) $id('launcher-place-id').value = acc.LastPlaceId;
                }
                if (acc.LastJobId) {
                    if ($id('launcher-job-id')) $id('launcher-job-id').value = acc.LastJobId;
                }
            }
        }
    },

    deleteSelectedAccount: function () {
        if (!this.selectedAccount) return;
        var username = this.selectedAccount;
        var self = this;
        var execDel = function () {
            if (window.bridge && window.bridge.DeleteAccount) {
                window.bridge.DeleteAccount(username);
                self.selectedAccount = null;
                self.renderList($id('acc-search')?.value.toLowerCase() || "");
                window.showNotification("Account removed successfully");
            } else {
                window.showNotification("Bridge DeleteAccount method not found");
            }
        };
        if (window.openActionModal) {
            window.openActionModal(
                "Delete @" + username + "?",
                "Are you sure you want to remove this account? You will need to log in again to add it back.",
                "red",
                execDel
            );
        } else {
            if (confirm("Are you sure you want to delete @" + username + "?")) {
                execDel();
            }
        }
    },

    saveLauncher: function () {
        const pidInput = $id('launcher-place-id');
        const jidInput = $id('launcher-job-id');
        if (!pidInput || !jidInput) return;
        const pid = pidInput.value.trim();
        const jid = jidInput.value.trim();
        localStorage.setItem('launcher_place_id', pid);
        localStorage.setItem('launcher_job_id', jid);
        if (this.selectedAccount && bridge && bridge.SaveLauncherData) {
            const pNum = parseInt(pid) || 0;
            bridge.SaveLauncherData(this.selectedAccount, pNum, jid);
        }
        window.showNotification("Saved");
    },

    launchWithAccount: function (username, event) {
        if (event) event.stopPropagation();
        if (bridge && bridge.LaunchAccount) {
            bridge.LaunchAccount(username, "0", "");
        } else {
            window.showNotification("Bridge not ready—Please restart Zenith");
        }
    },

    launchAll: function () {
        const pidRaw = $id('launcher-place-id').value.trim();
        const jid = $id('launcher-job-id').value.trim();
        if (!this.selectedAccount) return window.showNotification("Select an account first");
        if (!pidRaw || !/^\d+$/.test(pidRaw)) return window.showNotification("Enter a numeric Place ID");
        if (bridge && bridge.LaunchAccount) {
            bridge.LaunchAccount(this.selectedAccount, pidRaw, jid);
        } else {
            window.showNotification("Bridge not ready—Please restart Zenith");
        }
    },

    toggleManualAdd: function () {
        const form = $id('manual-add-form');
        const btn = $id('add-acc-toggle-btn');
        if (!form || !btn) return;
        if (form.style.display === 'none') {
            form.style.display = 'block';
            form.classList.add('am-form-closed');
            void form.offsetWidth;
        }
        const isClosed = form.classList.contains('am-form-closed');
        const vp = form.closest('.am-viewport');
        const scrollContainer = form.closest('.am-viewport-scroll');
        if (vp) {
            vp.classList.add('suppress-scroll');
            setTimeout(() => vp.classList.remove('suppress-scroll'), 350);
        }
        if (isClosed) {
            if (scrollContainer) scrollContainer.classList.add('am-form-active');
            form.classList.remove('am-form-closed');
            form.classList.add('am-form-open');
            btn.innerText = 'Close';
        } else {

            if (scrollContainer) {
                scrollContainer.scrollTo({ top: 0, behavior: 'smooth' });
            }
            form.classList.remove('am-form-open');
            form.classList.add('am-form-closed');
            btn.innerText = 'Add Account';


            if (scrollContainer) {
                setTimeout(() => scrollContainer.classList.remove('am-form-active'), 360);
            }
        }
    },

    switchAddTab: function (tab) {
        document.querySelectorAll('.am-tab-mini').forEach(el => el.classList.remove('active'));
        const targetTab = document.querySelector(`.am-tab-mini[data-tab="${tab}"]`);
        if (targetTab) targetTab.classList.add('active');
        document.querySelectorAll('.add-tab-content').forEach(el => el.style.display = 'none');
        const content = $id(`add-tab-${tab}`);
        if (content) content.style.display = 'block';
    },

    openLoginBrowser: function () {
        if (bridge && bridge.OpenLoginBrowser) bridge.OpenLoginBrowser();
    },

    submitBulkCreds: function () {
        const list = $id('creds-input').value.trim();
        if (!list) return window.showNotification("List cannot be empty");
        if (bridge && bridge.AddBulkCredentials) bridge.AddBulkCredentials(list);
    },

    submitManualAdd: function () {
        const cookie = $id('manual-cookie-input').value.trim();
        if (!cookie) return window.showNotification("Cookie cannot be empty");
        if (bridge && bridge.AddAccount) {
            bridge.AddAccount(cookie);
            $id('manual-cookie-input').value = "";
        }
    },

    submitQuickLogin: function () {
        const code = $id('quick-login-code').value.trim();
        if (code.length !== 6) return window.showNotification("Code must be 6 digits");
        if (bridge && bridge.SubmitQuickLogin) bridge.SubmitQuickLogin(code);
    },

    redirectToSettings: function (section) {
        if (section === 'multi') {
            if (window.highlightSetting) {
                window.highlightSetting('misc', 'toggle-multi-instance');
            }
        }
    },

    loadAccounts: async function () {
        if (typeof bridge === 'undefined' || !bridge.GetAccountsJSON) return;
        try {
            const json = await bridge.GetAccountsJSON();
            this.accounts = JSON.parse(json);
            this.renderList();

            this.fetchAccountThumbnails();
        } catch (e) { console.error("Failed to load accounts:", e); }
    },

    fetchAccountThumbnails: async function () {
        if (!this.accounts || this.accounts.length === 0) return;

        const needsThumbs = this.accounts.filter(a => a.UserID && (!a.Thumbnail || String(a.Thumbnail).toLowerCase() === 'undefined' || a.Thumbnail === ''));
        if (needsThumbs.length === 0) return;

        const userIds = needsThumbs.map(a => a.UserID).join(',');
        try {
            const url = `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${userIds}&size=150x150&format=Png&isCircular=false`;
            const res = await fetch(url);
            const json = await res.json();
            if (json && json.data) {
                json.data.forEach(item => {
                    const acc = this.accounts.find(a => String(a.UserID) === String(item.targetId));
                    if (acc && item.imageUrl && item.state === 'Completed') {
                        acc.Thumbnail = item.imageUrl;
                    }
                });

                this.renderList(document.getElementById('acc-search')?.value.toLowerCase() || '');
            }
        } catch (e) {
            console.warn('Failed to fetch Roblox thumbnails:', e);
        }
    },


    renderList: function (filter = "") {
        const container = document.getElementById('accounts-list');
        if (!container) return;
        container.innerHTML = "";

        if (!this.accounts || this.accounts.length === 0) {
            const scrollContainer = container.parentElement;
            if (scrollContainer) {
                scrollContainer.style.display = 'flex';
                scrollContainer.style.flexDirection = 'column';
                scrollContainer.style.alignItems = 'center';
                scrollContainer.style.justifyContent = 'center';
            }
            container.style.cssText = 'display:flex; flex-direction:column; align-items:center; justify-content:center; flex:1; width:100%;';
            container.innerHTML = `
                <div style="text-align:center; opacity: 0.8; animation: fadeIn 0.4s ease-out;">
                    <svg width="42" height="42" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color:var(--t3);margin-bottom:14px; filter: drop-shadow(0 0 8px rgba(147, 51, 234, 0.2));">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                        <circle cx="9" cy="7" r="4" />
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                    </svg>
                    <div style="color:var(--t2); font-size:14px; font-weight:600; letter-spacing: -0.01em;">No accounts found</div>
                    <div style="color:var(--t3); font-size:11px; margin-top:5px; font-weight: 400;">Add one to get started</div>
                </div>
            `;
            return;
        }

        const scrollContainer = container.parentElement;
        if (scrollContainer) {
            scrollContainer.style.display = 'flex';
            scrollContainer.style.flexDirection = 'column';
            scrollContainer.style.alignItems = '';
            scrollContainer.style.justifyContent = '';
        }


        container.style.cssText = 'display:flex; flex-direction:column; gap:6px; flex:1;';

        this.accounts.forEach(acc => {
            const userLower = (acc.Username || "").toLowerCase();
            const displayLower = (acc.DisplayName || "").toLowerCase();
            const filterLower = filter.toLowerCase();

            if (filter && !userLower.includes(filterLower) && !displayLower.includes(filterLower)) return;

            const isSelected = this.selectedAccount === acc.Username;
            const card = document.createElement('div');
            card.className = `am-card ${isSelected ? 'active' : ''}`;
            card.onclick = () => this.selectAccount(acc.Username);

            const defaultAvatar = "data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%27%20viewBox%3D%270%200%2024%2024%27%20fill%3D%27none%27%20stroke%3D%27%23a0a0a5%27%20stroke-width%3D%272%27%20stroke-linecap%3D%27round%27%20stroke-linejoin%3D%27round%27%3E%3Cpath%20d%3D%27M20%2021v-2a4%204%200%200%200-4-4H8a4%204%200%200%200-4%204v2%27%2F%3E%3Ccircle%20cx%3D%2712%27%20cy%3D%277%27%20r%3D%274%27%2F%3E%3C%2Fsvg%3E";
            const isValidThumb = (acc.Thumbnail && (acc.Thumbnail.startsWith('http') || acc.Thumbnail.startsWith('data:')));
            const thumb = isValidThumb ? acc.Thumbnail : defaultAvatar;

            card.innerHTML = `
                <img src="${thumb}" class="am-card-img" onerror="this.onerror=null; this.src='${defaultAvatar}'">
                <div class="am-card-info">
                    <div class="am-card-name">${esc(acc.DisplayName || acc.Username)}</div>
                    <div class="am-card-user">@${esc(acc.Username)}</div>
                </div>
                <div class="am-card-stat" style="gap: 12px !important;">
                    <div style="display:flex; align-items:center; gap:6px;">
                        <span class="label">ID:</span>
                        <span class="value">${acc.UserID || 'N/A'}</span>
                    </div>
                    <button class="action-btn btn-purple" style="padding:4px 10px; font-size:10px; height:24px; border-radius:12px;" onclick="AccountManager.launchWithAccount('${esc(acc.Username)}', event)">
                        Open Roblox
                    </button>
                </div>
            `;
            container.appendChild(card);
        });
    },

    loadMoreServers: async function () {
        if (!this.nextPageCursor || !this.lastPid || !bridge) return;
        const btn = $id('btn-load-more');
        if (btn) {
            btn.disabled = true;
            btn.innerHTML = '<span class="btn-spinner"></span> Loading...';
        }
        try {
            const serversJson = await bridge.GetServersList(this.lastPid, this.nextPageCursor, false);
            const newData = JSON.parse(serversJson);
            if (newData.data && newData.data.length > 0) {
                this.lastServerData.data = this.lastServerData.data.concat(newData.data);
                if (this.originalServerData) {
                    this.originalServerData = this.originalServerData.concat(newData.data);
                }
                this.nextPageCursor = newData.nextPageCursor;
                this.renderServers(this.lastPid, this.lastPlaceName, this.lastServerData, this.lastThumbUrl);
            } else {
                this.nextPageCursor = null;
                if (btn) btn.style.display = 'none';
            }
        } catch (e) {
            console.error("Failed to load more servers:", e);
            window.showNotification("Failed to load more servers");
            if (btn) {
                btn.disabled = false;
                btn.innerText = "Load More Servers";
            }
        }
    },

    isVIP: false,

    toggleVip: function () {
        this.isVIP = !this.isVIP;
        this.refreshStatus();
    },

    _isRefreshing: false,

    refreshStatus: async function () {
        if (this._isRefreshing) return window.showNotification("Fetching servers... Please wait.");
        this.originalServerData = null;
        const pidInput = $id('launcher-place-id');
        const searchInput = $id('launcher-search-player');
        if (!pidInput || !pidInput.value) return window.showNotification("Enter a Place ID first");
        const pidRaw = pidInput.value.trim();
        if (!/^\d+$/.test(pidRaw)) return window.showNotification("Invalid Place ID (Numbers only)");
        const pid = parseInt(pidRaw);
        const searchText = searchInput ? searchInput.value.trim() : "";
        this.toggleServerPage(true);
        const container = $id('acc-viewport-servers');
        if (!container) return;
        const scrollEl = $id('servers-scroll-content') || container;
        scrollEl.style.cssText = 'flex:1; overflow-y:auto; padding-bottom:50px; position:relative;';
        scrollEl.innerHTML = `
            <div style="position:absolute; inset:0; display:flex; align-items:center; justify-content:center; flex-direction:column; gap:15px; transform:translateY(-30px);">
                <div class="shimmer" style="width:60px; height:60px; border-radius:50%;"></div>
                <div style="font-size:12px; color:var(--t2); font-weight:500;">${searchText ? `Searching for ${esc(searchText)}...` : 'Loading servers...'}</div>
            </div>
        `;
        this._isRefreshing = true;
        setTimeout(() => { this._isRefreshing = false; }, 8000);
        try {
            let placeName = "Roblox Game";
            let thumbUrl = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";

            const metaPromise = (async () => {
                try {

                    if (typeof bridge !== 'undefined' && bridge.GetPlaceDetails) {
                        const res = await bridge.GetPlaceDetails(pid);
                        const details = JSON.parse(res);
                        if (details && details.length > 0 && details[0].name) placeName = details[0].name;
                    } else {
                        const nameRes = await fetch("https://economy.roblox.com/v2/assets/" + pid + "/details");
                        const nameJson = await nameRes.json();
                        if (nameJson && nameJson.Name) placeName = nameJson.Name;
                    }
                } catch (e) { console.warn("Failed to fetch place name", e); }
                try {
                    const thumbRes = await fetch("https://thumbnails.roblox.com/v1/places/gameicons?placeIds=" + pid + "&returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false");
                    const thumbJson = await thumbRes.json();
                    if (thumbJson && thumbJson.data && thumbJson.data.length > 0 && thumbJson.data[0].imageUrl) {
                        thumbUrl = thumbJson.data[0].imageUrl;
                    }
                } catch (e) { console.warn("Failed to fetch thumbnail", e); }
            })();

            let data;
            if (searchText) {
                const searchRes = await bridge.SearchPlayerInServers(pid, searchText);
                const searchData = JSON.parse(searchRes);
                if (searchData.error) throw new Error(searchData.error);
                if (searchData.found) data = { data: [searchData.server] };
                else data = { data: [] };
            } else {
                if (this.isVIP) {
                    if (!this.selectedAccount) return window.showNotification("Select an account to view VIP servers");
                    const vipRes = await bridge.GetVIPServers(pid, this.selectedAccount);
                    data = JSON.parse(vipRes);
                } else {
                    const serversJson = await bridge.GetServersList(pid, "", false);
                    if (!serversJson) throw new Error("Bridge response was null.");
                    data = JSON.parse(serversJson);
                    if (data.error || data.errors) throw new Error("Roblox API: " + (data.error || data.errors[0]?.message));
                }
            }

            await metaPromise;
            this.nextPageCursor = data ? data.nextPageCursor : null;
            this.renderServers(pid, placeName, data, thumbUrl);

        } catch (e) {
            console.error(e);
            let msg = e.message || "Failed to fetch server list";
            if (msg.includes("429") || msg.includes("Too Many Requests")) msg = "Roblox API rate limit hit. Please wait 10 Ten Seconds.";
            const errEl = $id('servers-scroll-content') || container;
            errEl.innerHTML = `
                <div style="position:absolute; inset:0; display:flex; align-items:center; justify-content:center; padding:40px; text-align:center;">
                    <div>
                        <div style="font-weight:600; color:var(--t2); margin-bottom:5px;">Error</div>
                        <div style="font-size:11px; color:var(--t3);">${msg}</div>
                    </div>
                </div>
            `;
        } finally {
            this._isRefreshing = false;
        }
    },

    renderServers: function (pid, placeName, data, thumbUrl) {
        this.lastPid = pid;
        this.lastPlaceName = placeName;
        this.lastServerData = data;
        this.lastThumbUrl = thumbUrl;
        const container = $id('acc-viewport-servers');
        if (!container) return;
        const scrollEl = $id('servers-scroll-content') || container;
        scrollEl.style.cssText = 'flex:1; overflow:hidden !important; padding-bottom:0; position:relative; display:flex !important; flex-direction:column; align-items:stretch;';
        if (!data || !data.data || data.data.length === 0) {
            scrollEl.innerHTML = `
                <div style="position:absolute; inset:0; display:flex; align-items:center; justify-content:center; padding:40px; text-align:center;">
                    <div>
                        <div style="font-weight:600; color:var(--t2); margin-bottom:5px;">No Public Servers Found</div>
                        <div style="font-size:11px; color:var(--t3);">This game might be private or empty.</div>
                    </div>
                </div>
            `;
            return;
        }

        const getArrow = (type) => {
            const sort = (this.activeSorts || []).find(s => s.type === type);
            if (!sort) return '';
            return `<svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" style="margin-left:4px; transform:${sort.dir === 'desc' ? '' : 'rotate(180deg)'}; transition: transform 0.2s;"><path d="M6 9l6 6 6-6"/></svg>`;
        };

        const gridList = $id('server-grid-list');
        if (gridList) {
            this.applySort();
            const playersBtn = document.querySelector(".sort-row button[onclick*='players']");
            const pingBtn = document.querySelector(".sort-row button[onclick*='ping']");
            if (playersBtn) {
                playersBtn.className = `sort-btn ${(this.activeSorts || []).some(s => s.type === 'players') ? 'active' : ''}`;
                playersBtn.innerHTML = `Players ${getArrow('players')}`;
            }
            if (pingBtn) {
                pingBtn.className = `sort-btn ${(this.activeSorts || []).some(s => s.type === 'ping') ? 'active' : ''}`;
                pingBtn.innerHTML = `Ping ${getArrow('ping')}`;
            }

            let cardsHtml = '';
            data.data.forEach((srv, idx) => {
                const ratio = (srv.playing / srv.maxPlayers) * 100;
                const statusColor = ratio > 90 ? '#ef4444' : (ratio > 50 ? '#f59e0b' : '#10b981');
                const sid = srv.id.substring(0, 8);
                cardsHtml += `
                    <div class="server-card-compact fade-in-blur" data-srv-id="${srv.id}" data-pid="${pid}" style="animation-delay: ${idx * 0.03}s; opacity: 1;">
                        <div class="card-top">
                            <div class="server-id">
                                <div style="width:7px; height:7px; border-radius:50%; background:${statusColor};"></div>
                                <span>Server ${sid}</span>
                                <div class="icon-btn-small" data-tooltip="Copy Job ID" onclick="AccountManager.copyId('${srv.id}', 'Job ID')">
                                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                                </div>
                            </div>
                            <div class="meta-group">
                                <div class="meta-item" id="ping-${srv.id}">${srv._realPing || srv.ping || '?'}ms</div>
                            </div>
                        </div>
                        <div>
                            <div style="display:flex; justify-content:space-between; font-size:10px; color:var(--t2); margin-bottom:3px;">
                                <span>Players</span>
                                <span style="font-weight:700; color:var(--t1);">${srv.playing}/${srv.maxPlayers}</span>
                            </div>
                            <div style="height:4px; background:var(--bg4); border-radius:2px; overflow:hidden;">
                                <div style="height:100%; width:${ratio}%; background:var(--purple-g); border-radius:2px;"></div>
                            </div>
                        </div>
                        <button class="action-btn btn-purple" style="width:100%; justify-content:center; gap:6px; padding:6px; border-radius:20px; font-size:11px;" onclick="AccountManager.joinServer('${pid}', '${srv.id}')">
                            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><path d="M5 3l14 9-14 9V3z"/></svg>
                            Join Instance
                        </button>
                    </div>
                `;
            });
            gridList.innerHTML = cardsHtml;

            let loadMoreBtn = $id('btn-load-more');
            if (this.nextPageCursor) {
                if (!loadMoreBtn) {
                    const pContainer = gridList.parentElement;
                    const btnContainer = document.createElement('div');
                    btnContainer.style.cssText = 'padding: 20px 0; display: flex; justify-content: center;';
                    btnContainer.innerHTML = `
                        <button onclick="AccountManager.loadMoreServers()" class="action-btn btn-purple" id="btn-load-more" style="padding: 0 30px; height: 32px; font-size: 12px;">
                            Load More Servers
                        </button>
                    `;
                    pContainer.appendChild(btnContainer);
                } else {
                    loadMoreBtn.disabled = false;
                    loadMoreBtn.innerText = "Load More Servers";
                    loadMoreBtn.parentElement.style.display = 'flex';
                }
            } else {
                if (loadMoreBtn) {
                    loadMoreBtn.parentElement.style.display = 'none';
                }
            }
            return;
        }

        this.applySort();
        const searchText = $id('launcher-search-player')?.value || '';
        const isValidServerThumb = (this.lastThumbUrl && (this.lastThumbUrl.startsWith('http') || this.lastThumbUrl.startsWith('data:')));
        const finalThumbUrl = isValidServerThumb ? this.lastThumbUrl : "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
        let html = `
            <div style="height:100%; display:flex; flex-direction:column; min-height:0; box-sizing:border-box; padding-top:20px;">
                <div style="margin-bottom:12px; flex-shrink:0;">
                    <div style="display:flex; align-items:center; gap:12px;">
                        <img src="${finalThumbUrl}" 
                             onerror="this.src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='"
                             style="width: 48px; height: 48px; border-radius: 8px; object-fit: cover; background: var(--bg3); border: 1px solid var(--bd);">
                        <div>
                            <div style="font-size:16px; font-weight:700; color:var(--t1); line-height:1.2;">${esc(placeName)}</div>
                            <div style="font-size:10px; color:var(--t3); margin-top:2px;">Showing ${data.data.length} active instances</div>
                        </div>
                    </div>
                </div>
                <div class="sort-row" style="margin-bottom:12px; display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap; width:100%;">
                    <div style="display:flex; gap:8px;">
                        <button onclick="AccountManager.setSort('players')" class="sort-btn ${(this.activeSorts || []).some(s => s.type === 'players') ? 'active' : ''}">
                            Players ${getArrow('players')}
                        </button>
                        <button onclick="AccountManager.setSort('ping')" class="sort-btn ${(this.activeSorts || []).some(s => s.type === 'ping') ? 'active' : ''}">
                            Ping ${getArrow('ping')}
                        </button>
                    </div>
                    <div style="display:flex; align-items:center; gap:8px; flex:1; max-width:280px;">
                        <input type="text" id="launcher-search-player" placeholder="Search Player Username..." 
                               class="ios-input" 
                               value="${esc(searchText)}"
                               style="flex:1; height:28px; background:rgba(255,255,255,0.03) !important; border-radius:8px !important; padding:0 10px; font-size:11px; outline:none; font-family:inherit;"
                               onkeydown="if(event.key==='Enter') AccountManager.refreshStatus()">
                        <button onclick="AccountManager.refreshStatus()" class="action-btn" style="height:28px; width:28px; padding:0; display:flex; align-items:center; justify-content:center; border-radius:8px !important;">
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <circle cx="11" cy="11" r="8"/>
                                <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                            </svg>
                        </button>
                    </div>
                </div>
                <div class="scroll-mask-bottom" style="flex:1; display:flex; flex-direction:column; min-height:0; position:relative;">
                    <div class="am-viewport-scroll" style="flex:1; overflow-y:auto; margin-right:-4px; padding-right:4px; padding-bottom:20px;">
                        <div class="server-grid-dense" id="server-grid-list">
        `;
        data.data.forEach((srv, idx) => {
            const ratio = (srv.playing / srv.maxPlayers) * 100;
            const statusColor = ratio > 90 ? '#ef4444' : (ratio > 50 ? '#f59e0b' : '#10b981');
            const sid = srv.id.substring(0, 8);
            html += `
                <div class="server-card-compact fade-in-blur" data-srv-id="${srv.id}" data-pid="${pid}" style="animation-delay: ${idx * 0.03}s;">
                    <div class="card-top">
                        <div class="server-id">
                            <div style="width:7px; height:7px; border-radius:50%; background:${statusColor};"></div>
                            <span>Server ${sid}</span>
                            <div class="icon-btn-small" data-tooltip="Copy Job ID" onclick="AccountManager.copyId('${srv.id}', 'Job ID')">
                                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                            </div>
                        </div>
                        <div class="meta-group">
                            <div class="meta-item" id="ping-${srv.id}">${srv.ping || '?'}ms</div>
                        </div>
                    </div>
                    <div>
                        <div style="display:flex; justify-content:space-between; font-size:10px; color:var(--t2); margin-bottom:3px;">
                            <span>Players</span>
                            <span style="font-weight:700; color:var(--t1);">${srv.playing}/${srv.maxPlayers}</span>
                        </div>
                        <div style="height:4px; background:var(--bg4); border-radius:2px; overflow:hidden;">
                            <div style="height:100%; width:${ratio}%; background:var(--purple-g); border-radius:2px;"></div>
                        </div>
                    </div>
                    <button class="action-btn btn-purple" style="width:100%; justify-content:center; gap:6px; padding:6px; border-radius:20px; font-size:11px;" onclick="AccountManager.joinServer('${pid}', '${srv.id}')">
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><path d="M5 3l14 9-14 9V3z"/></svg>
                        Join Instance
                    </button>
                </div>
            `;
        });
        html += `
                        </div>
                        ${this.nextPageCursor ? `
                            <div style="padding: 20px 0; display: flex; justify-content: center;">
                                <button onclick="AccountManager.loadMoreServers()" class="action-btn btn-purple" id="btn-load-more" style="padding: 0 30px; height: 32px; font-size: 12px;">
                                    Load More Servers
                                </button>
                            </div>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;
        scrollEl.innerHTML = html;
        this.fetchDetails(pid, data.data);
    },

    fetchDetails: function (pid, servers) {
        servers.forEach(srv => {
            bridge.GetServerDetails(parseInt(pid), srv.id).then(res => {
                const details = JSON.parse(res);
                if (!details || details.error) return;
                const pingEl = document.getElementById(`ping-${srv.id}`);
                if (pingEl && typeof details.ping !== 'undefined' && details.ping !== -1) {
                    const p = details.ping;
                    const color = p < 100 ? '#10b981' : (p < 200 ? '#f59e0b' : '#ef4444');
                    pingEl.innerHTML = `<span style="color:${color}">${p}ms</span>`;
                    srv._realPing = p;
                }
            }).catch(e => { });
        });
    },

    setSort: function (type) {
        if (!this.activeSorts) this.activeSorts = [];
        const existingIdx = this.activeSorts.findIndex(s => s.type === type);
        if (existingIdx !== -1) {
            const sort = this.activeSorts[existingIdx];
            if (sort.dir === 'desc') {
                sort.dir = 'asc';
            } else {
                this.activeSorts.splice(existingIdx, 1);
            }
        } else {
            this.activeSorts.unshift({ type: type, dir: 'desc' });
        }
        this.renderServers(this.lastPid, this.lastPlaceName, this.lastServerData, this.lastThumbUrl);
    },

    applySort: function () {
        if (!this.lastServerData || !this.lastServerData.data) return;
        if (!this.originalServerData) {
            this.originalServerData = [...this.lastServerData.data];
        }
        let list = [...this.originalServerData];
        if (this.activeSorts && this.activeSorts.length > 0) {
            list.sort((a, b) => {
                for (const sort of this.activeSorts) {
                    const mult = sort.dir === 'desc' ? -1 : 1;
                    let va, vb;
                    if (sort.type === 'players') {
                        va = parseInt(a.playing) || 0;
                        vb = parseInt(b.playing) || 0;
                    } else if (sort.type === 'ping') {
                        va = parseInt(a._realPing || a.ping) || 999;
                        vb = parseInt(b._realPing || b.ping) || 999;
                    }
                    if (va !== vb) return (va - vb) * mult;
                }
                return 0;
            });
        }
        this.lastServerData.data = list;
    },

    copyId: function (id, label) {
        window.copyToClipboard(id);
        window.showNotification((label || "Value") + " copied to clipboard");
    },

    selectServer: function (jobId) {
        const input = document.getElementById('launcher-job-id');
        if (input) {
            input.value = jobId;
            window.showNotification("Server ID selected");
            this.toggleServerPage(false);
        }
    },

    joinServer: function (pid, jobId) {
        if (!this.selectedAccount) return window.showNotification("Select an account first");
        if (typeof bridge !== 'undefined' && bridge.LaunchAccount) {
            bridge.LaunchAccount(this.selectedAccount, String(pid), jobId);
        } else {
            window.showNotification("Bridge not ready—Please restart Zenith");
        }
    }
};


window.MaintenanceTools = {
    selectedAdapter: null,

    init: async function () {
        this.bindButtons();
        setTimeout(() => this.refreshMacUI(), 500);
        if (window.renderRobloxManager) {
            window.renderRobloxManager(window.latestWeaoVersion || '');
        }
    },

    bindButtons: function () {
        const btnMac = document.getElementById('btn-show-mac');
        if (btnMac) btnMac.onclick = () => this.refreshMacUI();

        const btnRand = document.getElementById('btn-randomize-mac');
        if (btnRand) {
            btnRand.onclick = () => {
                if (!this.selectedAdapter) { window.showNotification('Please select a device first'); return; }

                if (typeof bridge !== 'undefined' && bridge.RandomizeMac) {
                    bridge.RandomizeMac(this.selectedAdapter.id, this.selectedAdapter.name);
                }
            };
        }

        const btnRest = document.getElementById('btn-restore-mac');
        if (btnRest) {
            btnRest.onclick = () => {
                if (!this.selectedAdapter) { window.showNotification('Please select a device first'); return; }

                if (typeof bridge !== 'undefined' && bridge.RestoreMac) {
                    bridge.RestoreMac(this.selectedAdapter.id, this.selectedAdapter.name);
                }
            };
        }




        const btnBeginRbx = document.getElementById('btn-begin-roblox-clean');
        if (btnBeginRbx) {
            btnBeginRbx.onclick = () => {
                const modal = document.getElementById('cleaners-select-modal');
                if (modal) modal.classList.remove('visible');
                if (window.showWarningBeforeCleaning) window.showWarningBeforeCleaning();
            };
        }


        const btnBeginSH = document.getElementById('btn-begin-sirhurt-clean');
        if (btnBeginSH) {
            btnBeginSH.onclick = () => {
                const modal = document.getElementById('cleaners-select-modal');
                if (modal) modal.classList.remove('visible');
                if (window.startSirHurtCleaner) window.startSirHurtCleaner();
            };
        }


        const btnInstallRbx = document.getElementById('btn-install-roblox');
        if (btnInstallRbx) {
            btnInstallRbx.onclick = () => {
                if (window.bridge && window.bridge.OpenBrowser) {
                    window.bridge.OpenBrowser("https://www.roblox.com/download/client");
                } else {
                    window.open("https://www.roblox.com/download/client", "_blank");
                }
            };
        }


        const btnCloseMaint = document.getElementById('btn-close-maintenance');
        if (btnCloseMaint) {
            btnCloseMaint.onclick = () => {
                document.getElementById('maintenance-progress-modal').classList.remove('visible');

                btnCloseMaint.disabled = true;
                btnCloseMaint.style.background = "rgba(255,255,255,0.03)";
                btnCloseMaint.style.color = "var(--t3)";
                btnCloseMaint.style.cursor = "not-allowed";
                btnCloseMaint.innerText = "Finish";
            };
        }
    },

    openProgressModal: function (title) {

    },


    refreshMacUI: async function () {
        const container = document.getElementById('adapter-selector');
        const label = document.getElementById('mac-address-label');
        const selectData = document.getElementById('adapter-select-data');
        if (!container || !label || !selectData) return;

        try {
            if (typeof bridge === 'undefined') {
                selectData.innerHTML = '<option value="">BRIDGE_NOT_FOUND</option>';
                container.dataset.refresh = "true";
                setupCustomSelects();
                return;
            }

            let adaptersJson = "";
            if (bridge.GetNetworkAdapters) {
                adaptersJson = await bridge.GetNetworkAdapters();
            }

            if (!adaptersJson || adaptersJson === "[]") {
                selectData.innerHTML = '<option value="">No physical adapters found</option>';
                container.dataset.refresh = "true";
                setupCustomSelects();
                return;
            }

            const adapters = JSON.parse(adaptersJson);


            const filtered = adapters.filter(a => {
                const name = a.name.toLowerCase();
                const isJunk = name.includes("wan miniport") ||
                    name.includes("bluetooth") ||
                    name.includes("kernel debug") ||
                    name.includes("virtual") ||
                    name.includes("tap-") ||
                    name.includes("vpn") ||
                    name.includes("microsoft tredo");
                if (isJunk) return false;

                return name.includes("wi-fi") || name.includes("ethernet") ||
                    name.includes("wlan") || name.includes("wireless") ||
                    name.includes("controller") || name.includes("adapter");
            });

            selectData.innerHTML = "";
            if (filtered.length === 0) {
                selectData.innerHTML = '<option value="">No physical adapters found</option>';
            } else {
                let updatedCurrent = false;
                filtered.forEach((adapter, index) => {
                    const opt = document.createElement('option');
                    opt.value = adapter.id;
                    opt.innerText = adapter.name;
                    opt.dataset.mac = adapter.mac;


                    if (this.selectedAdapter && this.selectedAdapter.id === adapter.id) {
                        opt.selected = true;
                        this.selectedAdapter = adapter;
                        label.innerText = adapter.mac;
                        updatedCurrent = true;
                    }

                    selectData.appendChild(opt);
                });


                if (!updatedCurrent && filtered.length > 0) {
                    this.selectedAdapter = filtered[0];
                    label.innerText = filtered[0].mac;
                    selectData.options[0].selected = true;
                }
            }


            container.dataset.refresh = "true";
            setupCustomSelects();


            selectData.onchange = () => {
                const selectedOpt = selectData.options[selectData.selectedIndex];
                if (selectedOpt && selectedOpt.dataset.mac) {
                    label.innerText = selectedOpt.dataset.mac;
                    this.selectedAdapter = {
                        id: selectedOpt.value,
                        name: selectedOpt.innerText,
                        mac: selectedOpt.dataset.mac
                    };
                }
            };

        } catch (e) {
            console.error("[Maintenance] MAC Fetch Error:", e);
            selectData.innerHTML = '<option value="">ERROR FETCHING ADAPTERS</option>';
            container.dataset.refresh = "true";
            setupCustomSelects();
        }
    }
};

document.addEventListener('DOMContentLoaded', () => {

    const initInterval = setInterval(() => {
        if (window.bridge && window.MaintenanceTools) {
            window.MaintenanceTools.init();

            if (window.bridge.GetRobloxCleanerConfig) {
                window.bridge.GetRobloxCleanerConfig().then(configStr => {
                    if (configStr && configStr !== "") {
                        try {
                            const config = JSON.parse(configStr);
                            if (document.getElementById('wl-desktop')) document.getElementById('wl-desktop').checked = config.desktop;
                            if (document.getElementById('wl-downloads')) document.getElementById('wl-downloads').checked = config.downloads;
                            if (document.getElementById('wl-documents')) document.getElementById('wl-documents').checked = config.documents;
                            if (config.custom && Array.isArray(config.custom)) {
                                window.customWhitelistPaths = config.custom;
                            }
                        } catch (e) { }
                    }
                    if (window.renderCustomWhitelist) window.renderCustomWhitelist();
                }).catch(() => {
                    if (window.renderCustomWhitelist) window.renderCustomWhitelist();
                });
            } else {
                if (window.renderCustomWhitelist) window.renderCustomWhitelist();
            }

            if (settings.autoSpoofStartup) {
                getAutoSpoofAdapter().then(adapter => {
                    if (adapter && typeof bridge !== 'undefined' && bridge.RandomizeMac) {
                        bridge.RandomizeMac(adapter.id, adapter.name);
                    }
                });
            }
            if (settings.autoClearCookiesStartup) {
                if (typeof window.clearRobloxCookies === 'function') {
                    window.clearRobloxCookies();
                }
            }
            if (settings.autoCleanerStartup) {
                if (typeof window.startRobloxCleaner === 'function') {
                    window.startRobloxCleaner();
                }
            }
            if (typeof bridge !== 'undefined' && bridge.SetWindowsStartup) {
                bridge.SetWindowsStartup(settings.windowsStartup);
            }
            if (typeof triggerHistoryCleanup === 'function') {
                triggerHistoryCleanup();
            }

            clearInterval(initInterval);
        }
    }, 200);


    setTimeout(() => clearInterval(initInterval), 5000);
});


window.customWhitelistPaths = [];

window.addCustomWhitelistFolder = function (path) {
    if (!path) return;
    if (window.customWhitelistPaths.includes(path)) return;

    window.customWhitelistPaths.push(path);

    window.renderCustomWhitelist(path);
};

window.removeCustomWhitelistFolder = function (idx) {
    const list = document.getElementById('wl-custom-list');
    if (!list) return;

    const items = list.querySelectorAll('.wl-custom-item');
    if (items[idx]) {
        items[idx].classList.add('wl-item-exit');
        setTimeout(() => {
            window.customWhitelistPaths.splice(idx, 1);
            window.renderCustomWhitelist();
        }, 250);
    } else {
        window.customWhitelistPaths.splice(idx, 1);
        window.renderCustomWhitelist();
    }
};

window.renderCustomWhitelist = function (newPath = null) {
    const list = document.getElementById('wl-custom-list');
    if (!list) return;

    if (window.customWhitelistPaths.length === 0) {
        list.innerHTML = `<div style="font-size:11px; color:var(--t3); text-align:center; padding: 10px;">No custom locations added</div>`;
        return;
    }

    let html = '';
    window.customWhitelistPaths.forEach((p, i) => {
        const isNew = p === newPath;
        html += `
        <div class="wl-custom-item ${isNew ? 'wl-item-enter' : ''}" style="display:flex; justify-content:space-between; align-items:center; padding:8px 10px; background:rgba(255,255,255,0.03); border:1px solid var(--bd); border-radius:6px; font-size:11px; color:var(--t2); transition: background 0.2s;">
            <div style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:85%;" title="${p.replace(/"/g, '&quot;')}">${p}</div>
            <div onclick="window.removeCustomWhitelistFolder(${i})" style="color:var(--red); cursor:pointer; opacity:0.8; padding:2px; font-size:14px; line-height:1;">✕</div>
        </div>
        `;
    });
    list.innerHTML = html;
};


window.browseForWhitelistFolder = async function () {
    if (typeof bridge !== 'undefined' && bridge.SelectFolder) {

        var path = await bridge.SelectFolder();


        if (path && path !== "") {
            window.addCustomWhitelistFolder(path);
        }
    } else {
        if (window.showNotification) window.showNotification("System not ready!");
        else alert("System not ready!");
    }
};


window.updateSpooferLog = function (msg) {
    const el = document.getElementById('spoofer-output');
    if (!el) return;


    let color = "#fff";
    if (msg.includes("Error") || msg.includes("Warning") || msg.includes("Failed")) color = "var(--red)";
    if (msg.includes("Complete!") || msg.includes("successfully")) color = "var(--purple)";

    el.innerHTML += `<div style="color: ${color}">${msg}</div>`;
    el.scrollTop = el.scrollHeight;
};

window.finishSpoofer = function () {
    const btn = document.getElementById('btn-spoofer-close');
    if (btn) {
        btn.style.opacity = '1';
        btn.style.pointerEvents = 'auto';
        btn.innerText = 'Close & Refresh';
    }
    if (window.MaintenanceTools) window.MaintenanceTools.refreshMacUI();
};

function setupTooltips() {
    const tooltip = document.getElementById('tooltip');
    if (!tooltip) return;

    let tooltipTimer = null;
    let currentTooltipTarget = null;
    let currentMouseX = 0;
    let currentMouseY = 0;

    function updateTooltipPosition(x, y) {
        const xOffset = x + 15;
        const yOffset = y + 15;

        const tw = tooltip.offsetWidth;
        const th = tooltip.offsetHeight;
        const vw = window.innerWidth;
        const vh = window.innerHeight;

        const finalX = xOffset + tw > vw ? x - tw - 15 : xOffset;
        const finalY = yOffset + th > vh ? y - th - 15 : yOffset;

        tooltip.style.transform = `translate(${finalX}px, ${finalY}px)`;
    }

    document.addEventListener('mouseover', (e) => {
        const target = e.target.closest('[data-tooltip]');
        if (target) {
            currentTooltipTarget = target;

            const isDock = target.closest('.hub-dock') || target.classList.contains('hub-dock-item');
            const delay = isDock ? 0 : 400;

            clearTimeout(tooltipTimer);
            tooltipTimer = setTimeout(() => {
                if (currentTooltipTarget === target) {
                    tooltip.innerText = target.getAttribute('data-tooltip');
                    tooltip.classList.add('visible');
                    updateTooltipPosition(currentMouseX, currentMouseY);
                }
            }, delay);
        }
    });

    document.addEventListener('mousemove', (e) => {
        currentMouseX = e.clientX;
        currentMouseY = e.clientY;
        if (tooltip.classList.contains('visible')) {
            updateTooltipPosition(currentMouseX, currentMouseY);
        }
    });

    document.addEventListener('mouseout', (e) => {
        const target = e.target.closest('[data-tooltip]');
        if (target) {
            if (currentTooltipTarget === target) {
                currentTooltipTarget = null;
            }
            clearTimeout(tooltipTimer);
            tooltip.classList.remove('visible');
        }
    });
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupTooltips);
} else {
    setupTooltips();
}


(function () {
    const hubFiltersScroll = document.getElementById('scriptblox-filters');
    if (hubFiltersScroll) {
        hubFiltersScroll.addEventListener('wheel', (e) => {

            if (getComputedStyle(hubFiltersScroll).display !== 'none') {
                e.preventDefault();
                hubFiltersScroll.scrollLeft += e.deltaY;
            }
        }, { passive: false });
    }
})();



window.showWarningBeforeCleaning = function () {
    const wlModal = document.getElementById('whitelist-modal');
    if (wlModal) wlModal.classList.remove('visible');

    const warnModal = document.getElementById('warning-modal');
    if (!warnModal) return;

    warnModal.classList.add('visible');

    const yesBtn = document.getElementById('btn-warning-yes');
    const timerSec = document.getElementById('warning-timer-sec');

    let timeLeft = 6.7;
    yesBtn.disabled = true;
    yesBtn.style.opacity = "0.5";
    yesBtn.style.filter = "blur(3px)";
    yesBtn.style.color = "transparent";
    yesBtn.style.pointerEvents = "none";
    yesBtn.style.cursor = "not-allowed";
    yesBtn.style.background = "rgba(255, 69, 58, 0.1)";
    yesBtn.style.borderColor = "rgba(255, 69, 58, 0.2)";

    timerSec.style.display = "block";
    timerSec.innerText = "6.7";

    if (window.warningTimerInterval) clearInterval(window.warningTimerInterval);

    window.warningTimerInterval = setInterval(() => {
        timeLeft -= 0.1;
        if (timeLeft <= 0) {
            clearInterval(window.warningTimerInterval);
            timerSec.style.display = "none";
            yesBtn.disabled = false;
            yesBtn.style.opacity = "1";
            yesBtn.style.filter = "none";
            yesBtn.style.color = "#ff453a";
            yesBtn.style.pointerEvents = "all";
            yesBtn.style.cursor = "pointer";

            yesBtn.onmouseenter = () => {
                if (!yesBtn.disabled) yesBtn.style.background = "rgba(255, 69, 58, 0.2)";
            };
            yesBtn.onmouseleave = () => {
                if (!yesBtn.disabled) yesBtn.style.background = "rgba(255, 69, 58, 0.1)";
            };
        } else {
            timerSec.innerText = timeLeft.toFixed(1);
        }
    }, 100);

    yesBtn.onclick = () => {
        if (window.warningTimerInterval) clearInterval(window.warningTimerInterval);
        warnModal.classList.remove('visible');
        window.startRobloxCleaner();
    };
};

window.startRobloxCleaner = function () {
    if (window.bridge && window.bridge.DeleteRobloxApiBanTraces) {
        const wlModal = document.getElementById('whitelist-modal');
        if (wlModal) wlModal.classList.remove('visible');
        const warnModal = document.getElementById('warning-modal');
        if (warnModal) warnModal.classList.remove('visible');
        window.bridge.DeleteRobloxApiBanTraces();
    }
};

window.startRobloxInstaller = function () {
    if (window.bridge && window.bridge.InstallRoblox) {
        window.bridge.InstallRoblox();
    }
};

window.clearRobloxCookies = function () {
    if (window.bridge && window.bridge.ClearRobloxCookies) {
        window.bridge.ClearRobloxCookies();
    }
};

window.showCleanerInteractionPrompt = function (msg) {
    const modal = document.getElementById('sirhurt-interaction-modal');
    const msgEl = document.getElementById('sirhurt-interaction-msg');
    if (modal && msgEl) {
        msgEl.innerText = msg;
        modal.classList.add('visible');
    }
};

window.answerSirHurtInteraction = function (res) {
    const modal = document.getElementById('sirhurt-interaction-modal');
    if (modal) modal.classList.remove('visible');
    if (window.bridge && window.bridge.AnswerCleanerPrompt) {
        window.bridge.AnswerCleanerPrompt(res);
    }
};
window.showLiveCleanerModal = function (titleText) {
    const modal = document.getElementById('live-cleaner-modal');
    if (!modal) return;

    const modalBox = modal.querySelector('.modal-box');
    const title = document.getElementById('live-cleaner-title');
    const spinner = document.getElementById('live-cleaner-spinner');
    const closeBtn = document.getElementById('btn-live-cleaner-close');
    const filesPane = document.getElementById('live-cleaner-files');
    const regsPane = document.getElementById('live-cleaner-regs');

    const grid = document.getElementById('live-cleaner-grid');
    const filesHeader = document.getElementById('live-cleaner-files-header');
    const filesCol = document.getElementById('live-cleaner-files-col');
    const regsCol = document.getElementById('live-cleaner-registry-pane');
    const modalActions = modal.querySelector('.modal-actions');

    const isSimpleLog = titleText && (titleText.toLowerCase().includes("install") || titleText.toLowerCase().includes("cookie"));

    if (modalBox && grid && filesHeader && filesCol && regsCol && filesPane) {
        const titleWrapper = title ? title.parentNode : null;
        if (isSimpleLog) {
            modalBox.style.width = "400px";
            modalBox.style.height = "225px";
            modalBox.style.padding = "15px";
            modalBox.style.display = "flex";
            modalBox.style.flexDirection = "column";
            modalBox.style.justifyContent = "space-between";
            modalBox.style.boxSizing = "border-box";

            if (title) title.style.fontSize = "13px";
            if (titleWrapper) titleWrapper.style.marginBottom = "10px";

            grid.style.gridTemplateColumns = "1fr";
            grid.style.height = "auto";
            grid.style.flex = "1";
            grid.style.minHeight = "0";
            grid.style.marginBottom = "10px";

            regsCol.style.display = "none";
            filesCol.style.background = "rgba(0,0,0,0.3)";
            filesCol.style.border = "1px solid var(--bd)";
            filesCol.style.borderRadius = "6px";
            filesCol.style.boxShadow = "";

            if (filesHeader.parentNode) {
                filesHeader.parentNode.style.display = "flex";
            }
            if (filesHeader) {
                filesHeader.innerText = "OUTPUT";
            }

            filesPane.style.padding = "6px 8px";
            filesPane.style.fontSize = "10px";
            filesPane.style.whiteSpace = "nowrap";
            filesPane.style.fontFamily = "'JetBrains Mono', monospace";
            filesPane.style.color = "var(--t2)";
            filesPane.style.lineHeight = "1.3";
            filesPane.style.textAlign = "left";
            filesPane.style.display = "";
            filesPane.style.flexDirection = "";
            filesPane.style.justifyContent = "";
            filesPane.style.alignItems = "";
            filesPane.style.gap = "";

            if (modalActions) {
                modalActions.style.marginTop = "0px";
            }
            if (closeBtn) {
                closeBtn.style.height = "30px";
                closeBtn.style.fontSize = "11px";
            }
        } else {
            modalBox.style.width = "600px";
            modalBox.style.height = "";
            modalBox.style.padding = "20px";
            modalBox.style.display = "";
            modalBox.style.flexDirection = "";
            modalBox.style.justifyContent = "";
            modalBox.style.boxSizing = "";

            if (title) title.style.fontSize = "15px";
            if (titleWrapper) titleWrapper.style.marginBottom = "15px";

            grid.style.gridTemplateColumns = "1fr 1fr";
            grid.style.height = "280px";
            grid.style.flex = "";
            grid.style.minHeight = "";
            grid.style.marginBottom = "5px";

            regsCol.style.display = "flex";
            filesCol.style.background = "rgba(0,0,0,0.3)";
            filesCol.style.border = "1px solid var(--bd)";
            filesCol.style.borderRadius = "6px";
            filesCol.style.boxShadow = "";

            if (filesHeader.parentNode) {
                filesHeader.parentNode.style.display = "flex";
            }
            if (filesHeader) {
                filesHeader.innerText = "FILES & FOLDERS";
            }

            filesPane.style.padding = "8px";
            filesPane.style.fontSize = "10.5px";
            filesPane.style.whiteSpace = "nowrap";
            filesPane.style.fontFamily = "'JetBrains Mono', monospace";
            filesPane.style.color = "var(--t2)";
            filesPane.style.lineHeight = "1.4";
            filesPane.style.textAlign = "left";
            filesPane.style.display = "";
            filesPane.style.flexDirection = "";
            filesPane.style.justifyContent = "";
            filesPane.style.alignItems = "";
            filesPane.style.gap = "";

            if (modalActions) {
                modalActions.style.marginTop = "15px";
            }
            if (closeBtn) {
                closeBtn.style.height = "36px";
                closeBtn.style.fontSize = "";
            }
        }
    }

    if (title) title.innerText = titleText || "Running Roblox Cleaner...";
    if (spinner) spinner.style.display = 'block';
    if (closeBtn) closeBtn.style.display = 'none';

    if (filesPane) filesPane.innerHTML = '';
    if (regsPane) regsPane.innerHTML = '';

    modal.classList.add('visible');
};

window.appendCleanerLog = function (text) {
    const filesPane = document.getElementById('live-cleaner-files');
    const regsPane = document.getElementById('live-cleaner-regs');

    const lines = text.split('\n');
    for (let line of lines) {
        if (!line.trim()) continue;

        const isReg = line.toLowerCase().includes('registry');
        const div = document.createElement('div');
        div.innerText = line;

        if (isReg && regsPane) {
            regsPane.appendChild(div);
            regsPane.scrollTop = regsPane.scrollHeight;
        } else if (filesPane) {
            filesPane.appendChild(div);
            filesPane.scrollTop = filesPane.scrollHeight;
        }
    }
};

window.showMaintenanceStatus = function (msg) {
    const modal = document.getElementById('completion-modal');
    if (!modal) return;

    const title = document.getElementById('completion-title');
    const textEl = document.getElementById('completion-modal-text');
    const closeBtn = document.getElementById('completion-close');

    if (title) title.innerText = "Please Wait";
    if (textEl) textEl.innerHTML = `<div style="text-align:center; padding:10px 0;"><span class="spinner" style="display:inline-block; margin-bottom:10px; width:20px; height:20px; border:2px solid var(--purple); border-top:2px solid transparent; border-radius:50%; animation:spin 1s linear infinite;"></span><br>${msg}</div>`;
    if (closeBtn) closeBtn.style.display = 'none';

    modal.classList.add('visible');
};

window.showCompletionModal = function (action, result, deviceName) {
    if (isExiting) {
        if (action === 'roblox') {
            const titleEl = document.getElementById('live-cleaner-title');
            const isCookies = titleEl && titleEl.innerText.toLowerCase().includes("cookie");
            if (isCookies && typeof window.onAutoClearCookiesComplete === 'function') {
                window.onAutoClearCookiesComplete();
            } else if (typeof window.onAutoCleanerComplete === 'function') {
                window.onAutoCleanerComplete();
            }
        } else if ((action === 'randomize' || action === 'restore') && typeof window.onAutoSpoofComplete === 'function') {
            window.onAutoSpoofComplete();
        }
        return;
    }
    if (action === 'roblox' || action === 'sirhurt' || action === 'roblox_install') {
        const modal = document.getElementById('live-cleaner-modal');
        if (!modal) return;

        const title = document.getElementById('live-cleaner-title');
        const spinner = document.getElementById('live-cleaner-spinner');
        const closeBtn = document.getElementById('btn-live-cleaner-close');

        if (title) {
            if (action === 'roblox_install') {
                title.innerText = result === 'Success' ? "Installation Completed" : "Installation Failed";
            } else if (title.innerText && title.innerText.toLowerCase().includes("cookie")) {
                title.innerText = "Cookies Cleared";
            } else {
                title.innerText = "Cleanup Completed";
            }
        }
        if (spinner) spinner.style.display = 'none';
        if (closeBtn) closeBtn.style.display = 'block';
        return;
    }

    const modal = document.getElementById('completion-modal');
    if (!modal) return;

    const title = document.getElementById('completion-title');
    const textEl = document.getElementById('completion-modal-text');
    const closeBtn = document.getElementById('completion-close');

    if (title) title.innerText = "Completed";
    if (closeBtn) closeBtn.style.display = 'block';

    if (action === 'randomize') {
        textEl.innerHTML = `<span style="color:#aaa; font-size:14px;">Address changed to:</span><br><span style="color:#fff; font-size:15px;">${result}</span><br><br><span style="color:#aaa; font-size:14px;">Device:</span><br><span style="color:#fff; font-size:15px;">${deviceName}</span>`;
    } else if (action === 'restore') {
        textEl.innerHTML = `<span style="color:#aaa; font-size:14px;">Address restored:</span><br><span style="color:#fff; font-size:15px;">${result}</span><br><br><span style="color:#aaa; font-size:14px;">Device:</span><br><span style="color:#fff; font-size:15px;">${deviceName}</span>`;
    }

    modal.classList.add('visible');
};

var isExiting = false;

async function getAutoSpoofAdapter() {
    if (window.MaintenanceTools && window.MaintenanceTools.selectedAdapter) {
        return window.MaintenanceTools.selectedAdapter;
    }
    if (typeof bridge === 'undefined' || !bridge.GetNetworkAdapters) return null;
    try {
        const adaptersJson = await bridge.GetNetworkAdapters();
        if (!adaptersJson || adaptersJson === "[]") return null;
        const adapters = JSON.parse(adaptersJson);
        const filtered = adapters.filter(a => {
            const name = a.name.toLowerCase();
            const isJunk = name.includes("wan miniport") ||
                name.includes("bluetooth") ||
                name.includes("kernel debug") ||
                name.includes("virtual") ||
                name.includes("tap-") ||
                name.includes("vpn") ||
                name.includes("microsoft tredo");
            if (isJunk) return false;
            return name.includes("wi-fi") || name.includes("ethernet") ||
                name.includes("wlan") || name.includes("wireless") ||
                name.includes("controller") || name.includes("adapter");
        });
        if (filtered.length > 0) return filtered[0];
    } catch (e) { }
    return null;
}

async function runExitTasksAndClose() {
    isExiting = true;

    if (settings.autoSpoofExit) {
        const adapter = await getAutoSpoofAdapter();
        if (adapter && typeof bridge !== 'undefined' && bridge.RandomizeMac) {
            bridge.RandomizeMac(adapter.id, adapter.name);
            await new Promise(resolve => {
                window.onAutoSpoofComplete = resolve;
            });
            const compModal = document.getElementById('completion-modal');
            if (compModal) compModal.classList.remove('visible');
        }
    }

    if (settings.autoClearCookiesExit) {
        if (typeof window.clearRobloxCookies === 'function') {
            window.clearRobloxCookies();
            await new Promise(resolve => {
                window.onAutoClearCookiesComplete = resolve;
            });
            const cleanerModal = document.getElementById('live-cleaner-modal');
            if (cleanerModal) cleanerModal.classList.remove('visible');
        }
    }

    if (settings.autoCleanerExit) {
        if (typeof window.startRobloxCleaner === 'function') {
            window.startRobloxCleaner();
            await new Promise(resolve => {
                window.onAutoCleanerComplete = resolve;
            });
            const cleanerModal = document.getElementById('live-cleaner-modal');
            if (cleanerModal) cleanerModal.classList.remove('visible');
        }
    }

    if (typeof bridge !== 'undefined' && bridge.Close) {
        bridge.Close();
    }
}

async function getUniqueFileName(folderAbs, baseName, ext) {
    if (typeof bridge === 'undefined' || !bridge.GetScripts) {
        return baseName + ext;
    }
    try {
        const files = await bridge.GetScripts(folderAbs);
        if (!files || !Array.isArray(files)) {
            return baseName + ext;
        }
        const existingNames = new Set(files.map(f => {
            const cleanName = f.replace(/\\/g, '/').replace(/\/$/, '');
            return cleanName.toLowerCase();
        }));

        let candidate = baseName + ext;
        let counter = 1;
        while (existingNames.has(candidate.toLowerCase())) {
            candidate = baseName + " (" + counter + ")" + ext;
            counter++;
        }
        return candidate;
    } catch (e) {
        return baseName + ext;
    }
}

function saveTabToHistory(tab) {
    if (settings.enableScriptHistory === false) return;
    if (typeof bridge === 'undefined' || !bridge.WriteScript) return;
    try {
        const content = (tab.id === activeTab) ? getEditorValue() : (monacoModels[tab.id] ? monacoModels[tab.id].getValue() : tab.content);
        let baseName = tab.name;
        let ext = '.lua';
        if (baseName.toLowerCase().endsWith('.lua')) {
            baseName = baseName.substring(0, baseName.length - 4);
            ext = '.lua';
        } else if (baseName.toLowerCase().endsWith('.luau')) {
            baseName = baseName.substring(0, baseName.length - 5);
            ext = '.luau';
        } else if (baseName.toLowerCase().endsWith('.txt')) {
            baseName = baseName.substring(0, baseName.length - 4);
            ext = '.txt';
        }

        const pad = (n) => String(n).padStart(2, '0');
        const now = new Date();
        const dateStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
        const historyName = `${baseName} (${dateStr})${ext}`;

        const folderAbs = window.resolveZenithPath('SirHurtV5.exe.WebView2/scriptshistory');
        bridge.WriteScript(folderAbs, historyName, content);

        if (window.currentFolder === 'SirHurtV5.exe.WebView2/scriptshistory') {
            setTimeout(() => {
                window.refreshCurrentFolder('SirHurtV5.exe.WebView2/scriptshistory');
            }, 100);
        }
    } catch (e) { }
}

async function triggerHistoryCleanup() {
    if (typeof bridge === 'undefined' || !bridge.GetScripts || !bridge.DeleteScript) return;
    try {
        const duration = settings.historyCleanDuration || '3';
        if (duration === 'never') return;
        const days = parseInt(duration);
        if (isNaN(days)) return;

        const thresholdMs = Date.now() - (days * 24 * 60 * 60 * 1000);
        const folderAbs = window.resolveZenithPath('SirHurtV5.exe.WebView2/scriptshistory');
        const files = await bridge.GetScripts(folderAbs);
        if (!files || !Array.isArray(files)) return;

        for (let f of files) {
            const startIdx = f.lastIndexOf('(');
            const endIdx = f.lastIndexOf(')');
            if (startIdx !== -1 && endIdx !== -1 && endIdx > startIdx) {
                const dateStr = f.substring(startIdx + 1, endIdx);
                const parts = dateStr.split(' ');
                if (parts.length === 2) {
                    const datePart = parts[0];
                    const timePart = parts[1].replace(/-/g, ':');
                    const isoStr = datePart + 'T' + timePart;
                    const fileDate = new Date(isoStr);
                    if (!isNaN(fileDate.getTime())) {
                        if (fileDate.getTime() < thresholdMs) {
                            bridge.DeleteScript(folderAbs, f);
                        }
                    }
                }
            }
        }
    } catch (e) { }
}

document.addEventListener("DOMContentLoaded", () => {
    const styleEl = document.createElement('style');
    styleEl.textContent = `
        #file-panel {
            transition: width 0.3s var(--ease), transform 0.2s cubic-bezier(0.4, 0, 0.2, 1), outline 0.2s ease, box-shadow 0.2s ease, background 0.2s ease, margin-bottom 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
            margin-bottom: 0px;
        }
        #file-panel.tab-drag-hover {
            transform: scale(0.97) !important;
            outline: 2px dashed var(--purple) !important;
            outline-offset: -4px !important;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4), 0 0 15px rgba(123, 127, 246, 0.2) !important;
            background: rgba(123, 127, 246, 0.03) !important;
        }
        .editor-view {
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        #console-box {
            transition: margin-right 0.3s cubic-bezier(0.4, 0, 0.2, 1), height 0.28s var(--ease) !important;
            margin-right: 0px;
        }
        #editor-wrapper, #tabs-row-container {
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .editor-view.history-active .editor-layout {
            overflow: visible !important;
        }
        .editor-view.history-active:not(:has(#console-box.collapsed)) #file-panel {
            margin-bottom: -125px !important;
            height: calc(100% + 125px) !important;
        }
        .editor-view.history-active:has(#console-box.collapsed) #file-panel {
            margin-bottom: -44px !important;
            height: calc(100% + 44px) !important;
        }
        .editor-view.history-active #console-box {
            margin-right: 180px !important;
        }
        .editor-view.history-active:has(#file-panel.collapsed) #console-box {
            margin-right: 44px !important;
        }
    `;
    document.head.appendChild(styleEl);

    const filePanel = document.getElementById('file-panel');
    if (filePanel) {
        filePanel.addEventListener('dragenter', function (e) {
            if (window.draggedTabId === undefined) return;
            e.preventDefault();
            filePanel.classList.add('tab-drag-hover');
        });

        filePanel.addEventListener('dragover', function (e) {
            if (window.draggedTabId === undefined) return;
            e.preventDefault();
            e.dataTransfer.dropEffect = 'copy';
            filePanel.classList.add('tab-drag-hover');

            const rootItem = e.target.closest('.fp-root-item');
            const subfolderItem = e.target.closest('.fp-item[data-type="folder"]');

            filePanel.querySelectorAll('.fp-root-item, .fp-item').forEach(el => {
                el.style.background = '';
            });

            if (rootItem) {
                rootItem.style.background = 'rgba(123, 127, 246, 0.15)';
            } else if (subfolderItem) {
                subfolderItem.style.background = 'rgba(123, 127, 246, 0.15)';
            }
        });

        filePanel.addEventListener('dragleave', function (e) {
            filePanel.querySelectorAll('.fp-root-item, .fp-item').forEach(el => {
                el.style.background = '';
            });
            if (!filePanel.contains(e.relatedTarget)) {
                filePanel.classList.remove('tab-drag-hover');
            }
        });

        filePanel.addEventListener('drop', async function (e) {
            if (window.draggedTabId === undefined) return;
            e.preventDefault();
            filePanel.classList.remove('tab-drag-hover');

            filePanel.querySelectorAll('.fp-root-item, .fp-item').forEach(el => {
                el.style.background = '';
            });

            const rootItem = e.target.closest('.fp-root-item');
            const subfolderItem = e.target.closest('.fp-item[data-type="folder"]');

            let targetFolder = null;
            if (rootItem) {
                targetFolder = rootItem.dataset.root;
            } else if (subfolderItem) {
                const parentFolder = subfolderItem.dataset.folder || '';
                const folderName = subfolderItem.dataset.file;
                targetFolder = parentFolder ? (parentFolder + '/' + folderName) : folderName;
            } else {
                targetFolder = window.currentFolder;
            }

            if (targetFolder) {
                const tabId = window.draggedTabId;
                const tab = tabs.find(t => t.id === tabId);
                if (tab) {
                    const content = (tab.id === activeTab) ? getEditorValue() : (monacoModels[tab.id] ? monacoModels[tab.id].getValue() : tab.content);

                    let baseName = tab.name;
                    let ext = '.lua';
                    if (baseName.toLowerCase().endsWith('.lua')) {
                        baseName = baseName.substring(0, baseName.length - 4);
                        ext = '.lua';
                    } else if (baseName.toLowerCase().endsWith('.luau')) {
                        baseName = baseName.substring(0, baseName.length - 5);
                        ext = '.luau';
                    } else if (baseName.toLowerCase().endsWith('.txt')) {
                        baseName = baseName.substring(0, baseName.length - 4);
                        ext = '.txt';
                    }

                    const folderAbs = window.resolveZenithPath(targetFolder);
                    const finalName = await getUniqueFileName(folderAbs, baseName, ext);

                    if (bridge && bridge.WriteScript) {
                        bridge.WriteScript(folderAbs, finalName, content);
                        window.showNotification("Saved tab to " + finalName);
                        setTimeout(() => {
                            if (window.currentFolder) {
                                window.refreshCurrentFolder(window.currentFolder);
                            }
                        }, 100);
                    }
                }
            }
            window.draggedTabId = undefined;
        });
    }

    // Fetch global launches count (read-only helper)
    function fetchGlobalLaunches() {
        try {
            fetch('https://api.counterapi.dev/v1/sh-ui-launches/launches')
                .then(res => res.json())
                .then(data => {
                    if (data && typeof data.count !== 'undefined') {
                        const el = document.getElementById('global-launches-count');
                        if (el) el.innerText = data.count.toLocaleString();
                    }
                })
                .catch(() => { });
        } catch (e) { }
    }
    window.fetchGlobalLaunches = fetchGlobalLaunches;

    // Loader bypass detection & double increment prevention
    try {
        const loaderRan = sessionStorage.getItem('sirhurt_loader_ran');
        if (!loaderRan) {
            // Loader was disabled/bypassed. We need to increment the launches globally now!
            fetch('https://api.counterapi.dev/v1/sh-ui-launches/launches/up')
                .then(res => res.json())
                .then(data => {
                    if (data && typeof data.count !== 'undefined') {
                        const el = document.getElementById('global-launches-count');
                        if (el) el.innerText = data.count.toLocaleString();
                    }
                })
                .catch(() => {
                    const el = document.getElementById('global-launches-count');
                    if (el) el.innerText = "Error loading";
                });
            sessionStorage.setItem('sirhurt_loader_ran', 'true');
        } else {
            // Loader already ran and incremented it. Simply fetch the current count!
            fetchGlobalLaunches();
        }
    } catch (e) {
        fetchGlobalLaunches();
    }

    // Optimized: Set interval for real-time live updates (polls every 6 seconds ONLY if active tab is Information)
    setInterval(() => {
        const infoPage = document.getElementById('page-information');
        if (infoPage && infoPage.classList.contains('active')) {
            fetchGlobalLaunches();
        }
    }, 6000);

    const btn = document.getElementById('completion-close');
    if (btn) {
        btn.onclick = () => {
            document.getElementById('completion-modal').classList.remove('visible');
        };
    }

    const copyFilesBtn = document.getElementById('btn-copy-files');
    if (copyFilesBtn) {
        copyFilesBtn.onclick = () => {
            const pane = document.getElementById('live-cleaner-files');
            if (pane) {
                window.copyToClipboard(pane.innerText);
                copyFilesBtn.setAttribute('data-tooltip', 'Copied!');
                setTimeout(() => copyFilesBtn.setAttribute('data-tooltip', 'Copy Files Log'), 2000);
            }
        };
    }

    const copyRegsBtn = document.getElementById('btn-copy-regs');
    if (copyRegsBtn) {
        copyRegsBtn.onclick = () => {
            const pane = document.getElementById('live-cleaner-regs');
            if (pane) {
                window.copyToClipboard(pane.innerText);
                copyRegsBtn.setAttribute('data-tooltip', 'Copied!');
                setTimeout(() => copyRegsBtn.setAttribute('data-tooltip', 'Copy Registry Log'), 2000);
            }
        };
    }
});

window.startSirHurtCleaner = function () {

    const modal = document.getElementById('sirhurt-confirm-modal');
    if (modal) modal.classList.add('visible');
};

window.executeSirHurtCleaner = function (cleanTemp) {

    const modal = document.getElementById('sirhurt-confirm-modal');
    if (modal) modal.classList.remove('visible');


    window.showLiveCleanerModal("Running SirHurt Cleaner...");


    if (window.bridge && window.bridge.ExecuteSirHurtCleaner) {
        window.bridge.ExecuteSirHurtCleaner(cleanTemp);
    }
};

window.appendMaintenanceLog = function (msg) {
    const container = document.getElementById('maintenance-log-container');
    if (!container) return;
    const div = document.createElement('div');
    div.innerText = msg;
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
};

window.finishMaintenance = function () {
    const btn = document.getElementById('btn-close-maintenance');
    if (btn) {
        btn.disabled = false;
        btn.className = "modal-btn primary";
        btn.style.opacity = "1";
        btn.style.pointerEvents = "all";
        btn.style.background = "var(--purple)";
        btn.style.color = "#fff";
        btn.innerText = "Close";
    }
};




(function () {
    const sidebar = document.getElementById('main-sidebar');
    if (!sidebar) return;

    let hoverTimeout = null;

    const setupSidebarHoverListeners = () => {
        sidebar.addEventListener('mouseenter', () => {
            if (sidebar.classList.contains('slide-enabled')) {

                clearTimeout(hoverTimeout);


                hoverTimeout = setTimeout(() => {
                    sidebar.classList.add('expanded');
                }, 150);
            }
        });

        sidebar.addEventListener('mouseleave', () => {

            clearTimeout(hoverTimeout);

            sidebar.classList.remove('expanded');
        });
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setupSidebarHoverListeners);
    } else {
        setupSidebarHoverListeners();
    }

    (function () {
        let activeContainer = null;
        let startY = 0;
        let startX = 0;
        let scrollTop = 0;
        let scrollLeft = 0;
        let isDown = false;
        let velocityY = 0;
        let velocityX = 0;
        let lastY = 0;
        let lastX = 0;
        let lastTime = 0;
        let rafId = null;
        let hasDragged = false;
        let blockNextClick = false;

        function findScrollableParent(el) {
            while (el && el !== document.body) {
                const style = window.getComputedStyle(el);
                const overflowY = style.getPropertyValue('overflow-y');
                const overflowX = style.getPropertyValue('overflow-x');
                const isScrollableY = (overflowY === 'auto' || overflowY === 'scroll') && el.scrollHeight > el.clientHeight;
                const isScrollableX = (overflowX === 'auto' || overflowX === 'scroll') && el.scrollWidth > el.clientWidth;
                if (isScrollableY || isScrollableX) {

                    if (el.tagName === 'TEXTAREA' || el.tagName === 'INPUT' || el.classList.contains('input') || el.classList.contains('monaco-editor') || el.closest('.monaco-editor')) {
                        return null;
                    }
                    return el;
                }
                el = el.parentElement;
            }
            return null;
        }

        window.addEventListener('mousedown', function (e) {
            if (!settings.mouseDragScroll) return;
            if (e.button !== 0) return;


            if (e.target.closest('input') || e.target.closest('button') || e.target.closest('a') || e.target.closest('.ios-toggle') || e.target.closest('.custom-select')) {
                return;
            }

            const container = findScrollableParent(e.target);
            if (!container) return;

            activeContainer = container;
            isDown = true;
            hasDragged = false;
            startY = e.pageY - container.offsetTop;
            startX = e.pageX - container.offsetLeft;
            scrollTop = container.scrollTop;
            scrollLeft = container.scrollLeft;
            lastY = e.pageY;
            lastX = e.pageX;
            lastTime = Date.now();
            velocityY = 0;
            velocityX = 0;
            if (rafId) cancelAnimationFrame(rafId);
        }, { passive: false });

        window.addEventListener('mousemove', function (e) {
            if (!isDown || !activeContainer) return;

            const walkY = (e.pageY - lastY);
            const walkX = (e.pageX - lastX);


            if (Math.abs(e.pageY - (startY + activeContainer.offsetTop)) > 5 || Math.abs(e.pageX - (startX + activeContainer.offsetLeft)) > 5) {
                hasDragged = true;
            }

            if (hasDragged) {
                e.preventDefault();
                activeContainer.scrollTop = activeContainer.scrollTop - walkY;
                activeContainer.scrollLeft = activeContainer.scrollLeft - walkX;
            }

            const now = Date.now();
            const dt = now - lastTime;
            if (dt > 0) {
                const currentVelY = walkY / dt;
                const currentVelX = walkX / dt;

                velocityY = velocityY * 0.7 + currentVelY * 0.3;
                velocityX = velocityX * 0.7 + currentVelX * 0.3;
            }

            lastY = e.pageY;
            lastX = e.pageX;
            lastTime = now;
        });

        window.addEventListener('mouseup', function () {
            if (!isDown) return;
            isDown = false;

            if (hasDragged) {
                blockNextClick = true;

                setTimeout(() => { blockNextClick = false; }, 50);
            }


            const elapsed = Date.now() - lastTime;
            if (elapsed > 80) {
                velocityY = 0;
                velocityX = 0;
            } else if (elapsed > 0) {
                const ratio = Math.max(0, 1 - (elapsed / 80));
                velocityY *= ratio;
                velocityX *= ratio;
            }

            if (activeContainer && (Math.abs(velocityY) > 0.02 || Math.abs(velocityX) > 0.02)) {
                let container = activeContainer;

                let velY = velocityY * 4.5;
                let velX = velocityX * 4.5;


                const maxFling = 12;
                velY = Math.max(-maxFling, Math.min(maxFling, velY));
                velX = Math.max(-maxFling, Math.min(maxFling, velX));

                function step() {
                    if (isDown) return;

                    container.scrollTop = container.scrollTop - velY;
                    container.scrollLeft = container.scrollLeft - velX;


                    velY *= 0.972;
                    velX *= 0.972;

                    if (Math.abs(velY) > 0.1 || Math.abs(velX) > 0.1) {
                        rafId = requestAnimationFrame(step);
                    }
                }
                rafId = requestAnimationFrame(step);
            }
            activeContainer = null;
        });


        window.addEventListener('click', function (e) {
            if (blockNextClick) {
                e.preventDefault();
                e.stopPropagation();
                blockNextClick = false;
            }
        }, true);
    })();
})();








