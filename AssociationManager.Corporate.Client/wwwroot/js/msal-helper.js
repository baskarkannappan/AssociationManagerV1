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

        const msalInstance = new msal.PublicClientApplication(msalConfig);
        await msalInstance.initialize();

        // Handle any redirect results (even if using popups, this clears state)
        await msalInstance.handleRedirectPromise();

        try {
            const loginRequest = {
                scopes: [scope],
                prompt: "select_account"
            };

            const response = await msalInstance.loginPopup(loginRequest);
            return response.accessToken;
        } catch (error) {
            if (error.name === "BrowserAuthError" && error.errorCode === "interaction_in_progress") {
                console.warn("[MSAL] Interaction already in progress. Attempting to clear state...");
                // In some cases, clearing localStorage for MSAL can help if it's stuck
                for (let key in localStorage) {
                    if (key.startsWith("msal.")) {
                        localStorage.removeItem(key);
                    }
                }
                alert("Login interaction was stuck. We have cleared the state. Please try clicking 'Continue with Microsoft' again.");
            }
            console.error("MSAL Login Error:", error);
            throw error;
        }
    }
};
