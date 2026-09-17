const { ipcRenderer } = require('electron');

document.addEventListener('DOMContentLoaded', () => {
    // Window controls
    const closeBtn = document.getElementById('ban_control_close');
    const minimizeBtn = document.getElementById('ban_control_minimize');
    
    if (closeBtn) closeBtn.addEventListener('click', () => window.close());
    // (A real app would use ipc to minimize)

    // Navigation
    const navItems = {
        'nav-editor': 2,    // index of the editor page in the array of pages
        'nav-settings': 3,  // index of settings
        'nav-themes': 0,    // index of themes
        'nav-plugins': 1    // index of plugins
    };

    // The pages are stored as direct children of the relative container
    const pagesContainer = document.querySelector('.w-full.relative.h-full');
    if (pagesContainer) {
        const pages = pagesContainer.children;
        
        Object.keys(navItems).forEach(navId => {
            const btn = document.getElementById(navId);
            if (btn) {
                btn.addEventListener('click', () => {
                    // Remove drop-shadow and select class from all
                    Object.keys(navItems).forEach(id => {
                        const b = document.getElementById(id);
                        if (b) {
                            b.classList.remove('select', 'drop-shadow-md');
                        }
                    });

                    // Add to clicked
                    btn.classList.add('select', 'drop-shadow-md');

                    // Hide all pages
                    for(let i=0; i<pages.length; i++) {
                        pages[i].classList.remove('opacity-100', 'pointer-events-auto');
                        pages[i].classList.add('opacity-0', 'pointer-events-none');
                    }

                    // Show target page
                    const targetIdx = navItems[navId];
                    if(pages[targetIdx]) {
                        pages[targetIdx].classList.remove('opacity-0', 'pointer-events-none');
                        pages[targetIdx].classList.add('opacity-100', 'pointer-events-auto');
                    }
                });
            }
        });
    }

    // Theme Selector Mapping
    const themeFileMap = {
        'Cool Kid': '_prebuilt-coolkid.css',
        'Elysian Fields': '_prebuilt-elysian-fields.css',
        'Freeman': '_prebuilt-freeman.css',
        'Hollywood Classic': '_prebuilt-hollywood-classic.css',
        'Hollywood Dark': '_prebuilt-hollywood-dark.css',
        'Hollywood Glass': '_prebuilt-hollywood-glass.css',
        'Hollywood Light': '_prebuilt-hollywood-light.css',
        'Hollywood Novo': '_prebuilt-hollywood-novo.css',
        'Kyoto': '_prebuilt-kyoto.css',
        'Neon': '_prebuilt-neon.css',
        'Seven': '_prebuilt-seven.css',
        'Unikoi': '_prebuilt-unikoi.css'
    };

    const themeEntries = document.querySelectorAll('.dropdown-entry');
    themeEntries.forEach(entry => {
        entry.addEventListener('click', (e) => {
            const themeName = e.target.innerText.trim();
            const fileName = themeFileMap[themeName];
            if (fileName) {
                document.getElementById('theme-style').href = 'assets/styles/prebuilt/' + fileName;
                
                // Update highlighting in dropdown list
                document.querySelectorAll('.dropdown-entry').forEach(el => {
                    if (el.parentElement) el.parentElement.classList.remove('highlight');
                });
                if (e.target.parentElement) e.target.parentElement.classList.add('highlight');
            }
        });
    });

    // Theme dropdown toggler
    const themeSelector = document.querySelector('#theme-selector .selector');
    if (themeSelector) {
        themeSelector.addEventListener('click', () => {
            const list = themeSelector.nextElementSibling;
            if (list) {
                list.classList.toggle('hidden');
                list.classList.toggle('flex');
            }
        });
    }
});
