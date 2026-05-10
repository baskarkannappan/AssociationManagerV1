/**
 * Google Translate JS Helper - Cookie Based Version
 * This is the most reliable way to handle Google Translate in a SPA/Blazor app.
 */

window.languageHelper = {
    initialize: function (defaultLang) {
        console.log("[Language] Initializing. Default:", defaultLang);
        const savedLang = localStorage.getItem('app_language') || defaultLang || 'en';

        // 1. Ensure Google container exists (for their script to attach to)
        if (!document.getElementById('google_translate_element')) {
            const div = document.createElement('div');
            div.id = 'google_translate_element';
            div.style.display = 'none';
            document.body.appendChild(div);
        }

        // 2. Load Google Script if not present
        if (!window.googleTranslateElementInit) {
            window.googleTranslateElementInit = () => {
                new google.translate.TranslateElement({
                    pageLanguage: 'en',
                    includedLanguages: 'en,hi,ta,bn,ml,kn,te,mr,gu',
                    layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
                    autoDisplay: false
                }, 'google_translate_element');
            };

            const script = document.createElement('script');
            script.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
            script.async = true;
            document.head.appendChild(script);
        }

        return savedLang;
    },

    setLanguage: function (langCode) {
        console.log("[Language] Injecting Cookie for:", langCode);
        
        // Set the standard Google Translate cookie
        const cookieValue = `/en/${langCode}`;
        
        // Set for all possible paths to ensure it sticks
        document.cookie = "googtrans=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;"; // Clear old
        document.cookie = `googtrans=${cookieValue}; path=/;`;
        
        localStorage.setItem('app_language', langCode);

        // A reload is the only way to ensure the entire Blazor DOM is re-translated correctly
        window.location.reload();
        return true;
    }
};

// Clean up Google's UI artifacts
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
