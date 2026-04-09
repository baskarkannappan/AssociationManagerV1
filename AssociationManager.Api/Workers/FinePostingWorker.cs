using AssociationManager.Services.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace AssociationManager.Api.Workers;

public class FinePostingWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<FinePostingWorker> _logger;
    private readonly TimeSpan _checkInterval = TimeSpan.FromHours(24);

    public FinePostingWorker(IServiceProvider serviceProvider, ILogger<FinePostingWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Fine Posting Worker is starting.");

        while (!stoppingToken.IsCancellationRequested)
        {
            _logger.LogInformation("Fine Posting Worker is checking for overdue fines...");

            try
            {
                using (var scope = _serviceProvider.CreateScope())
                {
                    var financeService = scope.ServiceProvider.GetRequiredService<IFinanceService>();
                    int postedCount = await financeService.PostOverdueFinesAsync();
                    
                    if (postedCount > 0)
                    {
                        _logger.LogInformation("Fine Posting Worker successfully posted {Count} fines.", postedCount);
                    }
                    else
                    {
                        _logger.LogInformation("Fine Posting Worker found no new fines to post.");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while posting overdue fines.");
            }

            await Task.Delay(_checkInterval, stoppingToken);
        }

        _logger.LogInformation("Fine Posting Worker is stopping.");
    }
}
