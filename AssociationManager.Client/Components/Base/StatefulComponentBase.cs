using Microsoft.AspNetCore.Components;
using System;
using System.Collections.Generic;
using System.Linq;

namespace AssociationManager.Client.Components.Base
{
    public abstract class StatefulComponentBase : ComponentBase, IDisposable
    {
        private readonly List<Action> _subscriptions = new();
        private bool _disposed;

        [Inject]
        protected NavigationManager Navigation { get; set; } = default!;

        protected bool IsLoading { get; set; }

        protected void SubscribeToStateChanged(params Action?[] stateChangedEvents)
        {
            foreach (var evt in stateChangedEvents)
            {
                if (evt != null)
                {
                    // Note: This is an architectural simplification. 
                    // In a real app, you'd subscribe to the specific service event.
                    // For this helper, we assume the caller passes the service.Notify event handler.
                }
            }
        }

        // Standard subscription helper for our State Services
        protected void RegisterStateService(params dynamic[] services)
        {
            foreach (var service in services)
            {
                try 
                {
                    // Check if service has an OnChange event
                    var eventInfo = service.GetType().GetEvent("OnChange");
                    if (eventInfo != null)
                    {
                        Action handler = () => InvokeAsync(StateHasChanged);
                        eventInfo.AddEventHandler(service, handler);
                        _subscriptions.Add(() => eventInfo.RemoveEventHandler(service, handler));
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error subscribing to state service: {ex.Message}");
                }
            }
        }

        public virtual void Dispose()
        {
            if (_disposed) return;
            _disposed = true;

            foreach (var unsubscribe in _subscriptions)
            {
                unsubscribe();
            }
            _subscriptions.Clear();
        }
    }
}
