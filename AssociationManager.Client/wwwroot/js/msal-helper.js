window.msalHelper = {
    login: async function (clientId, authority, scope) {
        console.log("[MSAL] Initializing with Authority:", authority);
        const msalConfig = {
            auth: {
                clientId: clientId,
                authority: authority,
                validateAuthority: true,
                knownAuthorities: ["assocmgruat.ciamlogin.com"]
            },
            cache: {
                cacheLocation: "localStorage",
                storeAuthStateInCookie: false
            }
        };

        // Force a clear of any stuck states before starting
        for (let key in localStorage) {
            if (key.startsWith("msal.")) {
                localStorage.removeItem(key);
            }
        }

        const msalInstance = new msal.PublicClientApplication(msalConfig);
        await msalInstance.initialize();

        try {
            const loginRequest = {
                scopes: [scope],
                prompt: "select_account",
                redirectUri: window.location.origin + "/" 
            };

            console.log("[MSAL] Starting login with Redirect URI:", loginRequest.redirectUri);
            // Switch from popup to redirect to avoid COOP issues
            await msalInstance.loginRedirect(loginRequest);
            return null; // Will reload the page
        } catch (error) {
            console.error("MSAL Login Error:", error);
            throw error;
        }
    },
    handleRedirect: async function(clientId, authority, scope) {
        const msalConfig = {
            auth: {
                clientId: clientId,
                authority: authority,
                redirectUri: window.location.origin + "/"
            },
            cache: {
                cacheLocation: "sessionStorage",
                storeAuthStateInCookie: false
            }
        };

        const msalInstance = new msal.PublicClientApplication(msalConfig);
        await msalInstance.initialize();

        const response = await msalInstance.handleRedirectPromise();
        if (response) {
            console.log("[MSAL] Redirect response found:", response);
            return response.accessToken;
        }
        return null;
    }
};
