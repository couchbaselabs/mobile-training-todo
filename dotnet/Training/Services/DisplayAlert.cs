using System.Threading.Tasks;
using Training.Services;
using Xamarin.Forms;

[assembly: Dependency(typeof(DisplayAlert))]
namespace Training.Services
{
    public class DisplayAlert : ContentPage, IDisplayAlert
    {
        public async Task<string> DisplayActionSheetAsync(string title, string cancel, string destruction, params string[] buttons)
        {
            return await Application.Current.MainPage.DisplayActionSheet(title, cancel, destruction, buttons);
        }

        public async Task<bool> DisplayAlertAsync(string title, string message, string accept, string cancel)
        {
            return await Application.Current.MainPage.DisplayAlert(Title, message, accept, cancel);
        }

        public async Task DisplayAlertAsync(string title, string message, string cancel)
        {
            await Application.Current.MainPage.DisplayAlert(Title, message, cancel);
        }
    }
}
