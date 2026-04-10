using System;
using System.Collections.Generic;

namespace AssociationManager.Client.Services
{
    public class LayoutStateService
    {
        public event Action? OnChange;
        private void NotifyChanged() => OnChange?.Invoke();

        public string PageTitle { get; private set; } = "Home";
        public string? PageIcon { get; private set; }
        public List<AppBreadcrumbItem> Breadcrumbs { get; private set; } = new();
        public bool IsLoading { get; private set; }

        public void SetPageMetadata(string title, string? icon = null, List<AppBreadcrumbItem>? breadcrumbs = null)
        {
            PageTitle = title;
            PageIcon = icon;
            Breadcrumbs = breadcrumbs ?? new List<AppBreadcrumbItem>();
            NotifyChanged();
        }

        public void SetLoading(bool isLoading)
        {
            if (IsLoading != isLoading)
            {
                IsLoading = isLoading;
                NotifyChanged();
            }
        }
    }

    public class AppBreadcrumbItem
    {
        public string Text { get; set; } = string.Empty;
        public string? Url { get; set; }
        public bool IsActive { get; set; }
    }
}
