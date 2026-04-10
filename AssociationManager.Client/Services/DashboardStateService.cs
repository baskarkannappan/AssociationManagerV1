using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;

namespace AssociationManager.Client.Services;

public class DashboardStateService
{
    private readonly ApiService _apiService;
    private readonly GovernanceService _governanceService;
    private readonly ITenantContext _tenantContext;

    public DashboardStateService(ApiService apiService, GovernanceService governanceService, ITenantContext tenantContext)
    {
        _apiService = apiService;
        _governanceService = governanceService;
        _tenantContext = tenantContext;
    }

    public event Action? OnChange;

    // State Variables
    public AssociationDashboardMetrics? AdminMetrics { get; private set; }
    public ResidentDashboardMetrics? ResidentMetrics { get; private set; }
    public List<CommitteeMember>? Committee { get; private set; }
    public List<Meeting>? Meetings { get; private set; }
    public AssociationProfile? Profile { get; private set; }
    
    // Admin specific cards
    public int TotalMembers { get; private set; }
    public int CommitteeCount { get; private set; }
    public decimal Revenue30D { get; private set; }
    public decimal NetOutstanding { get; private set; }
    public decimal HeldAdvanceMoney { get; private set; }
    public int UnitsWithCredit { get; private set; }

    // Resident specific
    public List<Occupancy>? Occupancies { get; private set; }
    public decimal MyBalance { get; private set; }
    public List<Invoice>? MyInvoices { get; private set; }
    public Asset? MyUnit { get; private set; }
    public bool IsPrimaryOwner { get; private set; }

    public bool IsLoadingAdmin { get; private set; }
    public bool IsLoadingResident { get; private set; }

    public async Task InitializeAsync(bool isManagement, bool isResident)
    {
        if (isManagement) await LoadAdminDataAsync();
        else if (isResident) await LoadResidentDataAsync();
    }

    public async Task LoadAdminDataAsync()
    {
        IsLoadingAdmin = true;
        
        // Reset state to avoid showing stale data from previous association
        AdminMetrics = null;
        TotalMembers = 0;
        CommitteeCount = 0;
        Revenue30D = 0;
        NetOutstanding = 0;
        HeldAdvanceMoney = 0;
        UnitsWithCredit = 0;
        
        NotifyStateChanged();

        try 
        {
            Profile = await _governanceService.GetProfileAsync(_tenantContext.AssociationId);
            Committee = await _governanceService.GetCommitteeMembersAsync(true, _tenantContext.AssociationId);
            Meetings = await _governanceService.GetMeetingsAsync(_tenantContext.AssociationId);

        var tasks = new List<Task>
        {
            Task.Run(async () => AdminMetrics = await _apiService.GetAsync<AssociationDashboardMetrics>($"api/dashboard/admin/metrics?associationId={_tenantContext.AssociationId}")),
            Task.Run(async () => TotalMembers = await _apiService.GetAsync<int>($"api/dashboard/admin/total-members?associationId={_tenantContext.AssociationId}")),
            Task.Run(async () => CommitteeCount = await _apiService.GetAsync<int>($"api/dashboard/admin/committee-count?associationId={_tenantContext.AssociationId}")),
            Task.Run(async () => Revenue30D = await _apiService.GetAsync<decimal>($"api/dashboard/admin/revenue-30d?associationId={_tenantContext.AssociationId}")),
            Task.Run(async () => NetOutstanding = await _apiService.GetAsync<decimal>($"api/dashboard/admin/outstanding?associationId={_tenantContext.AssociationId}")),
            Task.Run(async () => {
                var adv = await _apiService.GetAsync<AdvanceMoneyMetrics>($"api/dashboard/admin/advance-money?associationId={_tenantContext.AssociationId}");
                if (adv != null) {
                    HeldAdvanceMoney = adv.TotalAdvanceCredits;
                    UnitsWithCredit = adv.UnitsWithCredit;
                }
            })
            };

            await Task.WhenAll(tasks);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Dashboard] Error loading admin metrics: {ex.Message}");
        }

        IsLoadingAdmin = false;
        NotifyStateChanged();
    }

    public async Task LoadResidentDataAsync()
    {
        IsLoadingResident = true;
        
        // Reset state
        ResidentMetrics = null;
        Occupancies = null;
        MyUnit = null;
        
        NotifyStateChanged();

        try
        {
            Occupancies = (await _apiService.GetAsync<IEnumerable<Occupancy>>("api/people/my-occupancy"))?.ToList() ?? new();
            IsPrimaryOwner = Occupancies.Any(o => o.IsPrimaryContact || o.OccupancyType == OccupancyType.Owner);
            
            MyBalance = await _apiService.GetAsync<decimal>("api/finance/balance/asset");
            var invoiceResult = await _apiService.GetAsync<PagedResult<Invoice>>("api/finance/invoices?pageSize=50");
            MyInvoices = invoiceResult?.Items?.ToList();
            ResidentMetrics = await _apiService.GetAsync<ResidentDashboardMetrics>($"api/dashboard/resident/metrics?associationId={_tenantContext.AssociationId}");

            if (Occupancies.Count == 1)
            {
                MyUnit = await _apiService.GetAsync<Asset>($"api/assets/{Occupancies[0].AssetId}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading resident data: {ex.Message}");
        }

        IsLoadingResident = false;
        NotifyStateChanged();
    }

    public string GetTimeAgo(DateTime dateTime)
    {
        var span = DateTime.UtcNow - dateTime.ToUniversalTime();
        if (span.TotalMinutes < 60) return $"{(int)span.TotalMinutes} mins ago";
        if (span.TotalHours < 24) return $"{(int)span.TotalHours} hours ago";
        return dateTime.ToShortDateString();
    }

    private void NotifyStateChanged() => OnChange?.Invoke();
}
