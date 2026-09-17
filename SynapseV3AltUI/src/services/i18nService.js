/**
 * i18nService.js — original service reworked for an offline-only port:
 * translations are bundled via JSON imports instead of fetched from disk.
 */
import englishLang from '../../assets/lang/english.json';

export const LANGUAGES = [
    { id: 'english', name: 'English', file: 'english.json' },
    { id: 'portuguese-brazil', name: 'Português (Brasil)', file: 'portuguese-brazil.json' },
    { id: 'spanish', name: 'Español', file: 'spanish.json' },
    { id: 'filipino', name: 'Filipino', file: 'filipino.json' },
    { id: 'german', name: 'Deutsch', file: 'german.json' },
    { id: 'hungarian', name: 'Magyar', file: 'hungarian.json' },
    { id: 'indonesian', name: 'Bahasa Indonesia', file: 'indonesian.json' },
    { id: 'italian', name: 'Italiano', file: 'italian.json' },
    { id: 'korean', name: '한국어', file: 'korean.json' },
    { id: 'polish', name: 'Polski', file: 'polish.json' },
    { id: 'romanian', name: 'Română', file: 'romanian.json' },
    { id: 'slovak', name: 'Slovenčina', file: 'slovak.json' },
    { id: 'thai', name: 'ภาษาไทย', file: 'thai.json' },
    { id: 'turkish', name: 'Türkçe', file: 'turkish.json' },
    { id: 'vietnamese', name: 'Tiếng Việt', file: 'vietnamese.json' }
];

const files = import.meta.glob('../../assets/lang/*.json', { eager: true });
const bundles = Object.fromEntries(Object.entries(files).map(([file, mod]) => [file.split('/').pop(), mod.default?.translation || mod.default]));
const defaultEnglish = bundles['english.json'] || englishLang.translation || englishLang;

class I18nService {
    constructor() {
        this.currentLanguage = localStorage.getItem('synapse_setting_language') || 'english';
        this.fallbackTranslations = defaultEnglish;
        this.translations = this.currentLanguage === 'english' ? defaultEnglish : (bundles[`${this.currentLanguage}.json`] || {});
        this.listeners = new Set();
    }

    t(key, fallback = '') {
        if (!key) return fallback;
        if (this.translations && this.translations[key] !== undefined) {
            return this.translations[key];
        }
        if (this.fallbackTranslations && this.fallbackTranslations[key] !== undefined) {
            return this.fallbackTranslations[key];
        }
        return fallback || key;
    }

    async setLanguage(langId) {
        const langObj = LANGUAGES.find(l => l.id === langId) || LANGUAGES[0];
        this.currentLanguage = langObj.id;
        localStorage.setItem('synapse_setting_language', langObj.id);
        window.hwAPI?.setSetting?.('language', langObj.id);
        this.translations = langObj.id === 'english' ? this.fallbackTranslations : (bundles[langObj.file] || this.fallbackTranslations);
        this.notify();
    }

    getLanguage() {
        return this.currentLanguage;
    }

    subscribe(listener) {
        this.listeners.add(listener);
        return () => this.listeners.delete(listener);
    }

    notify() {
        this.listeners.forEach(cb => cb(this.currentLanguage));
    }
}

export const i18n = new I18nService();
window.i18n = i18n;
