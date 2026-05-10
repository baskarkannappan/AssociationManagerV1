/**
 * Google Translate JS Helper for Blazor
 * Fixed scope issues and added robust initialization checks.
 */

window.languageHelper = {
    initialize: function (defaultLang) {
        console.log("[Language] Initializing...");
        const savedLang = localStorage.getItem('app_language') || defaultLang;

        // 1. Ensure the hidden anchor element exists
        if (!document.getElementById('google_translate_element')) {
            const div = document.createElement('div');
            div.id = 'google_translate_element';
            div.style.display = 'none';
            document.body.appendChild(div);
        }

        // 2. Define the global callback that Google's script will call
        if (!window.googleTranslateElementInit) {
            window.googleTranslateElementInit = () => {
                console.log("[Language] Google Translate Widget Loaded");
                new google.translate.TranslateElement({
                    pageLanguage: 'en',
                    includedLanguages: 'en,hi,ta,bn,ml,kn,te,mr,gu',
                    layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
                    autoDisplay: false
                }, 'google_translate_element');

                // Apply saved language after a short delay to ensure DOM is ready
                if (savedLang && savedLang !== 'en') {
                    setTimeout(() => window.languageHelper.setLanguage(savedLang), 1000);
                }
            };

            // 3. Load the script
            console.log("[Language] Loading Google script...");
            const script = document.createElement('script');
            script.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
            script.async = true;
            script.onerror = () => console.error("[Language] Failed to load Google Translate script. Check your internet or ad-blocker.");
            document.head.appendChild(script);
        }

        return savedLang;
    },

    setLanguage: function (langCode) {
        console.log("[Language] Switching to:", langCode);
        localStorage.setItem('app_language', langCode);

        // Standard Google Translate combo box class
        const select = document.querySelector('.goog-te-combo');
        if (select) {
            select.value = langCode;
            select.dispatchEvent(new Event('change'));
            console.log("[Language] Change event dispatched");
            
            // If switching back to English, we sometimes need to clear the cookie
            if (langCode === 'en') {
                document.cookie = "googtrans=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
                document.cookie = "googtrans=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=" + document.domain;
            }
            return true;
        } else {
            console.log("[Language] Select element not found yet, retrying in 500ms...");
            setTimeout(() => window.languageHelper.setLanguage(langCode), 500);
            return false;
        }
    }
};

// CSS to keep the UI clean
if (!document.getElementById('lang-override-style')) {
    const style = document.createElement('style');
    style.id = 'lang-override-style';
    style.innerHTML = `
        .goog-te-banner-frame.skiptranslate, .goog-te-gadget-icon, .goog-te-menu-value span { display: none !important; }
        body { top: 0px !important; }
        #goog-gt-tt { display: none !important; visibility: hidden !important; }
        .goog-text-highlight { background-color: transparent !important; box-shadow: none !important; }
        .skiptranslate { display: none !important; }
        iframe.goog-te-banner-frame { display: none !important; }
    `;
    document.head.appendChild(style);
}
