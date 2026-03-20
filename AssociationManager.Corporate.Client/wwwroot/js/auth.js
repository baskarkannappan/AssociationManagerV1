window.handleCredentialResponse = (response) => {
    if (window.dotNetHelper) {
        window.dotNetHelper.invokeMethodAsync('HandleGoogleLogin', response.credential);
    }
};

window.setupGoogleCallback = (dotNetHelper) => {
    window.dotNetHelper = dotNetHelper;
};

window.renderGoogleButton = (clientId) => {
    const checkGsi = setInterval(() => {
        if (typeof google !== 'undefined' && google.accounts && google.accounts.id) {
            clearInterval(checkGsi);
            google.accounts.id.initialize({
                client_id: clientId,
                callback: window.handleCredentialResponse
            });
            const parent = document.getElementById('google-btn-parent');
            if (parent) {
                google.accounts.id.renderButton(parent, {
                    type: 'standard',
                    size: 'large',
                    theme: 'filled_black',
                    text: 'continue_with',
                    shape: 'pill',
                    logo_alignment: 'left'
                });
            }
        }
    }, 100);
};
