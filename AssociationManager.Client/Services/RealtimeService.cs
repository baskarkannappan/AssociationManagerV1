using Microsoft.AspNetCore.SignalR.Client;
using System;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class RealtimeService : IAsyncDisposable
{
    private HubConnection? _hubConnection;
    private readonly TokenService _tokenService;
    private readonly string _hubUrl;

    public RealtimeService(TokenService tokenService, string hubUrl)
    {
        _tokenService = tokenService;
        _hubUrl = hubUrl;
    }

    public event Action<string>? OnNotificationReceived;
    public event Action<int, string>? OnBatchCompleted;

    public async Task StartAsync()
    {
        var token = await _tokenService.GetToken();
        if (string.IsNullOrEmpty(token)) return;

        _hubConnection = new HubConnectionBuilder()
            .WithUrl(_hubUrl, options =>
            {
                options.AccessTokenProvider = () => Task.FromResult<string?>(token);
            })
            .WithAutomaticReconnect()
            .Build();

        _hubConnection.On<string>("ReceiveNotification", (message) =>
        {
            if (message.StartsWith("BATCH_READY|"))
            {
                var parts = message.Split('|');
                if (parts.Length == 3 && int.TryParse(parts[1], out int assocId))
                {
                    OnBatchCompleted?.Invoke(assocId, parts[2]);
                    return;
                }
            }
            OnNotificationReceived?.Invoke(message);
        });

        await _hubConnection.StartAsync();
    }

    public async Task JoinTenantGroupAsync(int tenantId)
    {
        if (_hubConnection != null && _hubConnection.State == HubConnectionState.Connected)
        {
            await _hubConnection.InvokeAsync("JoinTenantGroup", tenantId);
        }
    }

    public async Task LeaveTenantGroupAsync(int tenantId)
    {
        if (_hubConnection != null && _hubConnection.State == HubConnectionState.Connected)
        {
            await _hubConnection.InvokeAsync("LeaveTenantGroup", tenantId);
        }
    }

    public async ValueTask DisposeAsync()
    {
        if (_hubConnection != null)
        {
            await _hubConnection.DisposeAsync();
        }
    }
}
