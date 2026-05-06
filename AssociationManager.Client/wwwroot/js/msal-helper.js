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

        // Handle any redirect results
        await msalInstance.handleRedirectPromise();

        try {
            const loginRequest = {
                scopes: [scope],
                prompt: "select_account",
                // Explicitly set redirectUri to match the portal (with trailing slash)
                redirectUri: window.location.origin + "/" 
            };

            console.log("[MSAL] Starting login with Redirect URI:", loginRequest.redirectUri);
            const response = await msalInstance.loginPopup(loginRequest);
            return response.accessToken;
        } catch (error) {
            if (error.name === "BrowserAuthError" && (error.errorCode === "interaction_in_progress" || error.errorCode === "user_cancelled")) {
                console.warn("[MSAL] Interaction error detected. If you didn't close the window, this is a browser policy issue.");
            }
            console.error("MSAL Login Error:", error);
            throw error;
        }
    }
};
