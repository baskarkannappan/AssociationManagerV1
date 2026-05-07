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
                redirectUri: window.location.origin + "/" 
            };

            console.log("[MSAL] Starting loginRedirect...");
            await msalInstance.loginRedirect(loginRequest);
        } catch (error) {
            console.error("MSAL Login Error:", error);
            throw error;
        }
    },
    handleRedirect: async function(clientId, authority, scope) {
        console.log("[MSAL] Checking for Redirect Callback...");
        const msalConfig = {
            auth: {
                clientId: clientId,
                authority: authority,
                redirectUri: window.location.origin + "/",
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
            console.log("[MSAL] No redirect response found in cache.");
        } catch (error) {
            console.error("[MSAL] HandleRedirect Error:", error);
        }
        return null;
    }
};
