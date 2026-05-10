/**
 * Google Translate JS Helper for Blazor
 * Handles lazy-loading and programmatic translation triggering.
 */

window.languageHelper = {
    initialize: function (defaultLang) {
        // 1. Check localStorage for saved preference
        const savedLang = localStorage.getItem('app_language') || defaultLang;

        // 2. Add hidden Google Translate element if it doesn't exist
        if (!document.getElementById('google_translate_element')) {
            const div = document.createElement('div');
            div.id = 'google_translate_element';
            div.style.display = 'none';
            document.body.appendChild(div);
        }

        // 3. Lazy load the script
        if (!window.googleTranslateElementInit) {
            window.googleTranslateElementInit = () => {
                new google.translate.TranslateElement({
                    pageLanguage: 'en',
                    includedLanguages: 'en,hi,ta,bn,ml,kn,te,mr,gu',
                    layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
                    autoDisplay: false
                }, 'google_translate_element');

                // After initialization, if we have a saved lang, apply it
                if (savedLang !== 'en') {
                    this.setLanguage(savedLang);
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
        localStorage.setItem('app_language', langCode);

        const select = document.querySelector('.goog-te-combo');
        if (select) {
            select.value = langCode;
            select.dispatchEvent(new Event('change'));
            return true;
        } else {
            // If the widget isn't ready yet, retry in 500ms
            setTimeout(() => this.setLanguage(langCode), 500);
            return false;
        }
    },

    getLanguage: function () {
        return localStorage.getItem('app_language') || 'en';
    }
};

// Global CSS injection to hide the Google Translate toolbar
const style = document.createElement('style');
style.innerHTML = `
    .goog-te-banner-frame.skiptranslate, .goog-te-gadget-icon { display: none !important; }
    body { top: 0px !important; }
    .goog-te-menu-value { display: none !important; }
    #goog-gt-tt { display: none !important; }
    .goog-text-highlight { background-color: transparent !important; box-shadow: none !important; }
`;
document.head.appendChild(style);
