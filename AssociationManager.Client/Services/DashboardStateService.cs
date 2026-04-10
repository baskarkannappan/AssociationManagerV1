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

    private bool _isLoadingAdmin;
    public bool IsLoadingAdmin 
    { 
        get => _isLoadingAdmin; 
        private set { _isLoadingAdmin = value; NotifyStateChanged(); } 
    }

    private bool _isLoadingResident;
    public bool IsLoadingResident 
    { 
        get => _isLoadingResident; 
        private set { _isLoadingResident = value; NotifyStateChanged(); } 
    }

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
        Profile = null;
        Committee = null;
        Meetings = null;
        
        NotifyStateChanged();

        try 
        {
            var overview = await _apiService.GetAsync<AdminDashboardOverview>($"api/dashboard/admin/overview?associationId={_tenantContext.AssociationId}");
            if (overview != null)
            {
                AdminMetrics = overview.Metrics;
                TotalMembers = overview.TotalMembers;
                CommitteeCount = overview.CommitteeCount;
                Revenue30D = overview.Revenue30D;
                NetOutstanding = overview.NetOutstanding;
                HeldAdvanceMoney = overview.HeldAdvanceMoney;
                UnitsWithCredit = overview.UnitsWithCredit;
                Profile = overview.Profile;
                Committee = overview.Committee;
                Meetings = overview.UpcomingMeetings;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Dashboard] Error loading admin overview: {ex.Message}");
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
        MyInvoices = null;
        
        NotifyStateChanged();

        try
        {
            var overview = await _apiService.GetAsync<ResidentDashboardOverview>("api/dashboard/resident/overview");
            if (overview != null)
            {
                Occupancies = overview.Occupancies;
                IsPrimaryOwner = Occupancies.Any(o => o.IsPrimaryContact || o.OccupancyType == OccupancyType.Owner);
                MyBalance = overview.MyBalance;
                MyInvoices = overview.RecentInvoices;
                ResidentMetrics = overview.Metrics;
                MyUnit = overview.MyUnit;
                Profile = overview.Profile;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading resident dashboard overview: {ex.Message}");
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
