window.analytics = {
    initialize: function (measurementId) {
        if (!window.gtag) {
            console.warn("gtag.js not loaded. Analytics initialization skipped.");
            return;
        }
        window.gtag('config', measurementId, {
            'send_page_view': false // We handle page views manually in Blazor
        });
    },
    trackPageView: function (title, url) {
        if (window.gtag) {
            window.gtag('event', 'page_view', {
                'page_title': title,
                'page_location': url
            });
        }
    },
    setUserId: function (userId) {
        if (window.gtag) {
            window.gtag('set', 'user_properties', {
                'user_id': userId
            });
            // Also set for the config to ensure all subsequent events have it
            window.gtag('config', 'G-9JD8SHPC9P', {
                'user_id': userId
            });
        }
    }
};
