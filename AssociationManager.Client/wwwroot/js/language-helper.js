/**
 * Google Translate JS Helper for Blazor
 * Optimized for aggressive widget detection and reliability.
 */

console.log("!!! Language Helper Script Loaded !!!");

window.languageHelper = {
    timeoutId: null,

    initialize: function (defaultLang) {
        console.log("[Language] Initializing with default:", defaultLang);
        // We will default to 'en' unless something is already saved
        const savedLang = localStorage.getItem('app_language') || defaultLang || 'en';

        if (!document.getElementById('google_translate_element')) {
            const div = document.createElement('div');
            div.id = 'google_translate_element';
            // Some versions of Google Translate need the container to have some size to render children
            div.style.position = 'fixed';
            div.style.bottom = '0';
            div.style.right = '0';
            div.style.width = '1px';
            div.style.height = '1px';
            div.style.opacity = '0.01';
            div.style.pointerEvents = 'none';
            div.style.zIndex = '-1';
            document.body.appendChild(div);
        }

        if (!window.googleTranslateElementInit) {
            window.googleTranslateElementInit = () => {
                console.log("[Language] Google Translate Widget Callback Triggered");
                new google.translate.TranslateElement({
                    pageLanguage: 'en',
                    includedLanguages: 'en,hi,ta,bn,ml,kn,te,mr,gu',
                    layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
                    autoDisplay: false
                }, 'google_translate_element');

                // Initial application of saved language
                if (savedLang && savedLang !== 'en') {
                    console.log("[Language] Applying saved language on load:", savedLang);
                    setTimeout(() => window.languageHelper.setLanguage(savedLang), 2000);
                }
            };

            const script = document.createElement('script');
            script.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
            script.async = true;
            document.head.appendChild(script);
        }

        return savedLang;
    },

    setLanguage: function (langCode) {
        if (this.timeoutId) clearTimeout(this.timeoutId);

        console.log("[Language] Attempting switch to:", langCode);
        localStorage.setItem('app_language', langCode);

        // 1. Try standard selector
        let select = document.querySelector('.goog-te-combo');
        
        // 2. Try searching inside our container if not found
        if (!select) {
            const container = document.getElementById('google_translate_element');
            if (container) {
                select = container.querySelector('select');
            }
        }

        // 3. Try global search for any select with 'goog' in class
        if (!select) {
            const allSelects = document.querySelectorAll('select');
            for (let s of allSelects) {
                if (s.className && s.className.includes('goog')) {
                    select = s;
                    break;
                }
            }
        }

        if (select) {
            console.log("[Language] Widget found! Applying...");
            select.value = langCode;
            select.dispatchEvent(new Event('change'));
            
            if (langCode === 'en') {
                document.cookie = "googtrans=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
            }
            return true;
        } else {
            console.warn("[Language] Widget still not found, retrying in 1.5s...");
            this.timeoutId = setTimeout(() => window.languageHelper.setLanguage(langCode), 1500);
            return false;
        }
    }
};

// Global styles
if (!document.getElementById('lang-override-style')) {
    const style = document.createElement('style');
    style.id = 'lang-override-style';
    style.innerHTML = `
        .goog-te-banner-frame.skiptranslate, .goog-te-gadget-icon, .goog-te-menu-value span { display: none !important; }
        body { top: 0px !important; }
        #goog-gt-tt, .goog-te-balloon-frame { display: none !important; visibility: hidden !important; }
        .goog-text-highlight { background-color: transparent !important; box-shadow: none !important; }
        iframe.goog-te-banner-frame { display: none !important; }
    `;
    document.head.appendChild(style);
}
