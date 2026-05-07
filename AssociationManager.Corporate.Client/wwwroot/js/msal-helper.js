let msalInstance = null;

// The redirect URI must always be the root of the app so it is stable
// and only one URI needs to be registered in Azure App Registration.
function getRedirectUri() {
    return window.location.origin + '/';
}

async function getMsalInstance(clientId, authority) {
    if (msalInstance) return msalInstance;

    const msalConfig = {
        auth: {
            clientId: clientId,
            authority: authority,
            knownAuthorities: ["assocmgruat.ciamlogin.com", "0c8b323e-7dcf-4bf6-8eeb-3656cf1b673a.ciamlogin.com"],
            redirectUri: getRedirectUri()
        },
        cache: {
            cacheLocation: "localStorage",
            storeAuthStateInCookie: true
        }
    };

    msalInstance = new msal.PublicClientApplication(msalConfig);
    await msalInstance.initialize();
    return msalInstance;
}

window.msalHelper = {
    // Initiates the redirect login flow.
    // This function does NOT return a token - it navigates the browser to the IdP.
    // The token is returned by handleRedirect() after the user comes back.
    login: async function (clientId, authority, scope) {
        console.log("[MSAL] Starting Redirect Login flow...");
        const instance = await getMsalInstance(clientId, authority);

        // Handle any pending redirect first to avoid state conflicts
        try { await instance.handleRedirectPromise(); } catch(_) {}

        const loginRequest = {
            scopes: [scope],
            prompt: "select_account"
        };
        // loginRedirect navigates the browser away - nothing runs after this line
        await instance.loginRedirect(loginRequest);
    },

    // Called on page load to process the MSAL redirect response.
    // Returns the access token string if a redirect just completed, or null otherwise.
    handleRedirect: async function(clientId, authority, scope) {
        console.log("[MSAL] Checking for Redirect Callback...");
        const instance = await getMsalInstance(clientId, authority);

        try {
            const response = await instance.handleRedirectPromise();
            if (response && response.accessToken) {
                console.log("[MSAL] Redirect Success! Access token acquired for scopes:", response.scopes);
                return response.accessToken;
            }

            // If we have an account but no fresh redirect response, try silent token acquisition
            const accounts = instance.getAllAccounts();
            if (accounts.length > 0) {
                console.log("[MSAL] Account found, attempting silent token acquisition...");
                try {
                    const silentResult = await instance.acquireTokenSilent({
                        scopes: [scope],
                        account: accounts[0]
                    });
                    if (silentResult && silentResult.accessToken) {
                        console.log("[MSAL] Silent token acquired successfully.");
                        return silentResult.accessToken;
                    }
                } catch (silentError) {
                    console.warn("[MSAL] Silent acquisition failed:", silentError.message);
                }
            }

            console.log("[MSAL] No redirect response and no cached account found.");
        } catch (error) {
            console.error("[MSAL] HandleRedirect Error:", error.message || error);
        }
        return null;
    }
};
