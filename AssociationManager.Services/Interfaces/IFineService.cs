using AssociationManager.Shared.Models;
using System;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IFineService
{
    Task<decimal> CalculateFineAsync(Invoice invoice, DateTime atDate);
    Task<FineSettings?> GetSettingsAsync(int associationId);
    Task SaveSettingsAsync(FineSettings settings);
}
