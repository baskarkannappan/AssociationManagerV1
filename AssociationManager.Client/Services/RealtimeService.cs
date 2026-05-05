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
        OnBatchCompleted += (assocId, period, jobId, status) => { };
    }

    private int? _currentTenantId;
    private int? _currentAssociationId;

    public event Action<string>? OnNotificationReceived;
    public event Action<int, string, string?, string?> OnBatchCompleted;
    public event Action? OnHierarchyChanged;
    public event Action? OnReconnected;

    public async Task StartAsync()
    {
        try
        {
            if (_hubConnection != null && _hubConnection.State != HubConnectionState.Disconnected)
            {
                return; // Already started or starting
            }

            _hubConnection = new HubConnectionBuilder()
                .WithUrl(_hubUrl, options =>
                {
                    options.AccessTokenProvider = async () => await _tokenService.GetToken();
                })
                .WithAutomaticReconnect()
                .Build();

            _hubConnection.On<string>("ReceiveNotification", (message) =>
            {
                if (message.Contains("|"))
                {
                    var parts = message.Split('|');
                    var status = parts[0];
                    
                    if (status == "BATCH_READY" || status == "PREVIEW_READY" || status == "COMMIT_READY" || status == "COMMIT_FAILED")
                    {
                        if (parts.Length >= 3 && int.TryParse(parts[1], out int assocId))
                        {
                            var period = parts[2];
                            var jobId = parts.Length >= 4 ? parts[3] : null;
                            
                            OnBatchCompleted?.Invoke(assocId, period, jobId, status);
                            return;
                        }
                    }
                }
                OnNotificationReceived?.Invoke(message);
            });

            _hubConnection.On("HierarchyChanged", () =>
            {
                OnHierarchyChanged?.Invoke();
            });

            _hubConnection.Reconnected += async (connectionId) =>
            {
                if (_currentTenantId.HasValue) await JoinTenantGroupAsync(_currentTenantId.Value);
                if (_currentAssociationId.HasValue) await JoinAssociationGroupAsync(_currentAssociationId.Value);
                OnReconnected?.Invoke();
            };

            await _hubConnection.StartAsync();
            Console.WriteLine($"[Realtime] Connected to hub at {_hubUrl}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Realtime] ERROR: Could not connect to SignalR hub: {ex.Message}");
            throw; // Re-throw so the caller (MainLayout) can handle it gracefully
        }
    }

    public async Task JoinTenantGroupAsync(int tenantId)
    {
        _currentTenantId = tenantId;
        if (_hubConnection != null && _hubConnection.State == HubConnectionState.Connected)
        {
            await _hubConnection.InvokeAsync("JoinTenantGroup", tenantId);
        }
    }

    public async Task LeaveTenantGroupAsync(int tenantId)
    {
        _currentTenantId = null;
        if (_hubConnection != null && _hubConnection.State == HubConnectionState.Connected)
        {
            await _hubConnection.InvokeAsync("LeaveTenantGroup", tenantId);
        }
    }

    public async Task JoinAssociationGroupAsync(int associationId)
    {
        _currentAssociationId = associationId;
        if (_hubConnection != null && _hubConnection.State == HubConnectionState.Connected)
        {
            await _hubConnection.InvokeAsync("JoinAssociationGroup", associationId);
        }
    }

    public async Task LeaveAssociationGroupAsync(int associationId)
    {
        _currentAssociationId = null;
        if (_hubConnection != null && _hubConnection.State == HubConnectionState.Connected)
        {
            await _hubConnection.InvokeAsync("LeaveAssociationGroup", associationId);
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
