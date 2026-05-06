window.msalHelper = {
    login: async function (clientId, authority, scope) {
        const msalConfig = {
            auth: {
                clientId: clientId,
                authority: authority,
                validateAuthority: true
            },
            cache: {
                cacheLocation: "localStorage",
                storeAuthStateInCookie: false
            }
        };

        const msalInstance = new msal.PublicClientApplication(msalConfig);
        await msalInstance.initialize();

        try {
            const loginRequest = {
                scopes: [scope],
                prompt: "select_account"
            };

            const response = await msalInstance.loginPopup(loginRequest);
            return response.accessToken;
        } catch (error) {
            console.error("MSAL Login Error:", error);
            throw error;
        }
    }
};
