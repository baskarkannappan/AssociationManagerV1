using System;
using System.Threading.Tasks;

namespace AssociationManager.Services.Jobs;

public class TokenCleanupJob
{
    public Task RunAsync()
    {
        Console.WriteLine($"[Job] Cleaning up expired tokens at {DateTime.UtcNow}");
        // Implementation would call repo to delete expired tokens
        return Task.CompletedTask;
    }
}
