using System.Text.Json;

namespace AssociationManager.Mobile.Services;

public class MobileTokenStorageService
{
    private const string TokenKey = "auth_token";
    private const string TenantKey = "tenant_id";
    private const string AssociationKey = "association_id";
    private const string IsAdminKey = "is_admin";

    public async Task SaveTokenAsync(string token)
    {
        await SecureStorage.Default.SetAsync(TokenKey, token);
    }

    public async Task<string?> GetTokenAsync()
    {
        try 
        {
            // Set a 2-second timeout for SecureStorage to prevent white-screen hangs
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));
            var task = SecureStorage.Default.GetAsync(TokenKey);
            
            if (await Task.WhenAny(task, Task.Delay(2000, cts.Token)) == task)
            {
                return await task;
            }
            
            Console.WriteLine("[SECURE_STORAGE] Timeout occurred reading token.");
            return null;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SECURE_STORAGE] Exception: {ex.Message}");
            return null;
        }
    }

    public async Task SaveTenantContextAsync(int tenantId, int associationId, bool isAdmin)
    {
        await SecureStorage.Default.SetAsync(TenantKey, tenantId.ToString());
        await SecureStorage.Default.SetAsync(AssociationKey, associationId.ToString());
        await SecureStorage.Default.SetAsync(IsAdminKey, isAdmin.ToString());
    }

    public async Task<(int TenantId, int AssociationId, bool IsAdmin)> GetTenantContextAsync()
    {
        try
        {
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));

            var tenantTask = SecureStorage.Default.GetAsync(TenantKey);
            var assocTask = SecureStorage.Default.GetAsync(AssociationKey);
            var adminTask = SecureStorage.Default.GetAsync(IsAdminKey);

            var tenantStr = await Task.WhenAny(tenantTask, Task.Delay(2000, cts.Token)) == tenantTask ? await tenantTask : null;
            var assocStr = await Task.WhenAny(assocTask, Task.Delay(2000, cts.Token)) == assocTask ? await assocTask : null;
            var adminStr = await Task.WhenAny(adminTask, Task.Delay(2000, cts.Token)) == adminTask ? await adminTask : null;

            return (
                int.TryParse(tenantStr, out var t) ? t : 0,
                int.TryParse(assocStr, out var a) ? a : 0,
                bool.TryParse(adminStr, out var adm) ? adm : false
            );
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SECURE_STORAGE] Context Exception: {ex.Message}");
            return (0, 0, false);
        }
    }

    public void ClearAll()
    {
        SecureStorage.Default.RemoveAll();
    }
}
