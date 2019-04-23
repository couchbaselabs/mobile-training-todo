using System.Threading.Tasks;
using Acr.UserDialogs;
using CouchbaseLabs.MVVM.Services;
using CouchbaseLabs.MVVM.ViewModels;

namespace Training.ViewModels
{
    public abstract class BaseNavigationViewModel : BaseViewModel
    {
        protected INavigationService Navigation { get; set; }

        protected IUserDialogs Dialogs { get; }

        protected BaseNavigationViewModel(IUserDialogs dialogs)
        {
            Dialogs = dialogs;
        }

        protected BaseNavigationViewModel(INavigationService navigationService)
        {
            Navigation = navigationService;
        }

        protected BaseNavigationViewModel(INavigationService navigationService, IUserDialogs dialogs)
        {
            Navigation = navigationService;
            Dialogs = dialogs;
        }

        public Task Dismiss() => Navigation.PopAsync();
    }
}
