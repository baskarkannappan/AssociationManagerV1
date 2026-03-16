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
            OnNotificationReceived?.Invoke(message);
        });

        await _hubConnection.StartAsync();
    }

    public event Action<string>? OnNotificationReceived;

    public async ValueTask DisposeAsync()
    {
        if (_hubConnection != null)
        {
            await _hubConnection.DisposeAsync();
        }
    }
}
