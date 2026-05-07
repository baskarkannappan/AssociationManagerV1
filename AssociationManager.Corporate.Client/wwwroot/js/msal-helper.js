window.msalHelper = {
    login: async function (clientId, authority, scope) {
        console.log("[MSAL] Initializing Login with Authority:", authority);
        const msalConfig = {
            auth: {
                clientId: clientId,
                authority: authority,
                validateAuthority: true,
                knownAuthorities: ["assocmgruat.ciamlogin.com", "0c8b323e-7dcf-4bf6-8eeb-3656cf1b673a.ciamlogin.com"]
            },
            cache: {
                cacheLocation: "localStorage",
                storeAuthStateInCookie: true
            }
        };

        const msalInstance = new msal.PublicClientApplication(msalConfig);
        await msalInstance.initialize();

        try {
            const loginRequest = {
                scopes: [scope],
                prompt: "select_account",
                // Use current URL to ensure the return path is identical
                redirectUri: window.location.href.split('#')[0].split('?')[0] 
            };

            console.log("[MSAL] Starting loginRedirect to:", loginRequest.redirectUri);
            await msalInstance.loginRedirect(loginRequest);
        } catch (error) {
            console.error("MSAL Login Error:", error);
            throw error;
        }
    },
    handleRedirect: async function(clientId, authority, scope) {
        console.log("[MSAL] Checking for Redirect Callback at:", window.location.href);
        const msalConfig = {
            auth: {
                clientId: clientId,
                authority: authority,
                redirectUri: window.location.href.split('#')[0].split('?')[0],
                knownAuthorities: ["assocmgruat.ciamlogin.com", "0c8b323e-7dcf-4bf6-8eeb-3656cf1b673a.ciamlogin.com"]
            },
            cache: {
                cacheLocation: "localStorage",
                storeAuthStateInCookie: true
            }
        };

        const msalInstance = new msal.PublicClientApplication(msalConfig);
        await msalInstance.initialize();

        try {
            const response = await msalInstance.handleRedirectPromise();
            if (response) {
                console.log("[MSAL] Redirect Success! Token acquired.");
                return response.accessToken;
            }
            console.log("[MSAL] No redirect response found in cache/URL.");
        } catch (error) {
            console.error("[MSAL] HandleRedirect Error:", error);
        }
        return null;
    }
};
