namespace AssociationManager.Auth.Models;

public class JwtSettings
{
    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public int ExpiryInMinutes { get; set; } = 15;
    public int RefreshExpiryInDays { get; set; } = 7;
}

public class GoogleSettings
{
    public string ClientId { get; set; } = string.Empty;
}
