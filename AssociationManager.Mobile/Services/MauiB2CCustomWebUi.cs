using Microsoft.Identity.Client.Extensibility;
using System;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Maui.Authentication;
using Microsoft.Maui.ApplicationModel;

namespace AssociationManager.Mobile.Services
{
    public class MauiB2CCustomWebUi : ICustomWebUi
    {
        public async Task<Uri> AcquireAuthorizationCodeAsync(Uri authorizationUri, Uri redirectUri, CancellationToken cancellationToken)
        {
            try
            {
                // WebAuthenticator handles the Custom Tabs / ASWebAuthenticationSession natively via MAUI
                var result = await MainThread.InvokeOnMainThreadAsync(async () => 
                {
                    return await WebAuthenticator.Default.AuthenticateAsync(
                        new WebAuthenticatorOptions
                        {
                            Url = authorizationUri,
                            CallbackUrl = redirectUri,
                            PrefersEphemeralWebBrowserSession = false
                        });
                });

                // Reconstruct the callback URI with the parameters returned from the identity provider
                var uriBuilder = new UriBuilder(redirectUri);
                var query = new StringBuilder();
                
                foreach (var param in result.Properties)
                {
                    if (query.Length > 0)
                        query.Append('&');
                    
                    query.Append($"{Uri.EscapeDataString(param.Key)}={Uri.EscapeDataString(param.Value)}");
                }
                
                uriBuilder.Query = query.ToString();
                return uriBuilder.Uri;
            }
            catch (TaskCanceledException)
            {
                // The user canceled the login flow (closed the browser)
                return new Uri($"{redirectUri}?error=access_denied&error_description=Login+canceled+by+user.");
            }
            catch (Exception ex)
            {
                // Return an error to MSAL so it doesn't crash the app
                return new Uri($"{redirectUri}?error=server_error&error_description={Uri.EscapeDataString(ex.Message)}");
            }
        }
    }
}
