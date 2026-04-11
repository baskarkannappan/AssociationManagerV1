using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using System.Web;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ExternalAuthController : ControllerBase
{
    [HttpGet("google-login")]
    public IActionResult ChallengeGoogle()
    {
        // This serves a lightweight page that uses the same Google Client ID as the web portal
        // It provides the best user experience without needing a backend Client Secret.
        var clientId = "780387897793-0hvmtcnngq1eja17916219jtmk2rb7s4.apps.googleusercontent.com";
        var html = $@"
            <!DOCTYPE html>
            <html>
            <head>
                <title>Secure Sign-In</title>
                <script src=""https://accounts.google.com/gsi/client"" async defer></script>
                <style>
                    body {{ font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f8f9fa; }}
                    .card {{ background: white; padding: 2rem; border-radius: 8px; shadow: 0 4px 6px rgba(0,0,0,0.1); text-align: center; }}
                </style>
            </head>
            <body>
                <div class='card'>
                    <h3>AssociationManager</h3>
                    <p>Securing your mobile session...</p>
                    <div id=""g_id_onload""
                         data-client_id=""{clientId}""
                         data-context=""signin""
                         data-ux_mode=""popup""
                         data-callback=""handleCredentialResponse""
                         data-auto_prompt=""false"">
                    </div>
                    <div class=""g_id_signin""
                         data-type=""standard""
                         data-shape=""rectangular""
                         data-theme=""outline""
                         data-text=""signin_with""
                         data-size=""large""
                         data-logo_alignment=""left"">
                    </div>
                </div>
                <script>
                    function handleCredentialResponse(response) {{
                        const idToken = response.credential;
                        window.location.href = 'assocauth://callback?id_token=' + encodeURIComponent(idToken);
                    }}
                </script>
            </body>
            </html>";

        return Content(html, "text/html");
    }
}
