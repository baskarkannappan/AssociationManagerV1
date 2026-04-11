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
        return await SecureStorage.Default.GetAsync(TokenKey);
    }

    public async Task SaveTenantContextAsync(int tenantId, int associationId, bool isAdmin)
    {
        await SecureStorage.Default.SetAsync(TenantKey, tenantId.ToString());
        await SecureStorage.Default.SetAsync(AssociationKey, associationId.ToString());
        await SecureStorage.Default.SetAsync(IsAdminKey, isAdmin.ToString());
    }

    public async Task<(int TenantId, int AssociationId, bool IsAdmin)> GetTenantContextAsync()
    {
        var tenantStr = await SecureStorage.Default.GetAsync(TenantKey);
        var assocStr = await SecureStorage.Default.GetAsync(AssociationKey);
        var adminStr = await SecureStorage.Default.GetAsync(IsAdminKey);

        return (
            int.TryParse(tenantStr, out var t) ? t : 0,
            int.TryParse(assocStr, out var a) ? a : 0,
            bool.TryParse(adminStr, out var adm) ? adm : false
        );
    }

    public void ClearAll()
    {
        SecureStorage.Default.RemoveAll();
    }
}
