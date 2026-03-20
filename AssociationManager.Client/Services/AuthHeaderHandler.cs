using AssociationManager.Client.Services;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class AuthHeaderHandler : DelegatingHandler
{
    private readonly TokenService _tokenService;

    public AuthHeaderHandler(TokenService tokenService)
    {
        _tokenService = tokenService;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var token = await _tokenService.GetToken();
        if (!string.IsNullOrEmpty(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            System.Console.WriteLine($"[AuthHeaderHandler] Attaching token to {request.RequestUri}");
        }
        else
        {
            System.Console.WriteLine($"[AuthHeaderHandler] No token found for {request.RequestUri}");
        }

        return await base.SendAsync(request, cancellationToken);
    }
}
