let msalInstance = null;

async function getMsalInstance(clientId, authority) {
    if (msalInstance) return msalInstance;

    const msalConfig = {
        auth: {
            clientId: clientId,
            authority: authority,
            validateAuthority: true,
            knownAuthorities: ["assocmgruat.ciamlogin.com", "0c8b323e-7dcf-4bf6-8eeb-3656cf1b673a.ciamlogin.com"],
            redirectUri: window.location.href.split('#')[0].split('?')[0]
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
    login: async function (clientId, authority, scope) {
        console.log("[MSAL] Starting Login...");
        const instance = await getMsalInstance(clientId, authority);

        try {
            const loginRequest = {
                scopes: [scope],
                prompt: "select_account"
            };
            await instance.loginRedirect(loginRequest);
        } catch (error) {
            console.error("[MSAL] Login Error:", error);
            throw error;
        }
    },
    handleRedirect: async function(clientId, authority, scope) {
        console.log("[MSAL] Checking for Redirect Callback...");
        const instance = await getMsalInstance(clientId, authority);

        try {
            const response = await instance.handleRedirectPromise();
            if (response) {
                console.log("[MSAL] Redirect Success! Token acquired.");
                return response.accessToken;
            }
            console.log("[MSAL] No redirect response found.");
        } catch (error) {
            console.error("[MSAL] HandleRedirect Error:", error);
        }
        return null;
    }
};
