/**
 * Google Translate JS Helper for Blazor
 * Optimized to prevent infinite loops and ensure Google Translate renders correctly.
 */

console.log("!!! Language Helper Script Loaded !!!");

window.languageHelper = {
    timeoutId: null,

    initialize: function (defaultLang) {
        console.log("[Language] Initializing...");
        const savedLang = localStorage.getItem('app_language') || defaultLang;

        // Ensure the hidden anchor element exists but is not display:none (some browsers need it visible to render)
        if (!document.getElementById('google_translate_element')) {
            const div = document.createElement('div');
            div.id = 'google_translate_element';
            div.style.position = 'absolute';
            div.style.top = '-9999px';
            div.style.left = '-9999px';
            div.style.opacity = '0';
            div.style.pointerEvents = 'none';
            document.body.appendChild(div);
        }

        if (!window.googleTranslateElementInit) {
            window.googleTranslateElementInit = () => {
                console.log("[Language] Google Translate Widget Loaded");
                new google.translate.TranslateElement({
                    pageLanguage: 'en',
                    includedLanguages: 'en,hi,ta,bn,ml,kn,te,mr,gu',
                    layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
                    autoDisplay: false
                }, 'google_translate_element');

                if (savedLang && savedLang !== 'en') {
                    setTimeout(() => window.languageHelper.setLanguage(savedLang), 1500);
                }
            };

            const script = document.createElement('script');
            script.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
            script.async = true;
            script.onerror = () => console.error("[Language] Failed to load Google script.");
            document.head.appendChild(script);
        }

        return savedLang;
    },

    setLanguage: function (langCode) {
        // Clear any existing retry timer
        if (this.timeoutId) {
            clearTimeout(this.timeoutId);
            this.timeoutId = null;
        }

        console.log("[Language] Switching to:", langCode);
        localStorage.setItem('app_language', langCode);

        const select = document.querySelector('.goog-te-combo');
        if (select) {
            select.value = langCode;
            select.dispatchEvent(new Event('change'));
            console.log("[Language] Success");
            
            if (langCode === 'en') {
                document.cookie = "googtrans=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
            }
            return true;
        } else {
            console.log("[Language] Widget not found, retrying in 1000ms...");
            this.timeoutId = setTimeout(() => window.languageHelper.setLanguage(langCode), 1000);
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
