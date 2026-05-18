using Android.App;
using Android.Content;
using Microsoft.Identity.Client;

namespace AssociationManager.Mobile.Platforms.Android
{
    [Activity(Exported = true)]
    [IntentFilter(new[] { Intent.ActionView },
        Categories = new[] { Intent.CategoryBrowsable, Intent.CategoryDefault },
        DataScheme = "msalb6769384-144c-4c59-a9f5-02c201d4e769",
        DataHost = "auth")]
    public class MsalActivity : BrowserTabActivity
    {
    }
}
