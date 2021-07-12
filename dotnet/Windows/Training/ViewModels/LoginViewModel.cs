using System;
using Training.Services;
using Training.Views;
using Xamarin.Forms;

namespace Training.ViewModels
{
    public class LoginViewModel : BaseViewModel
    {
        private string _username;
        private string _password;

        public string Username
        {
            get => _username;
            set => SetProperty(ref _username, value);
        }

        public string Password
        {
            get => _password;
            set => SetProperty(ref _password, value);
        }

        public Command LoginCommand { get; }

        public LoginViewModel()
        {
            LoginCommand = new Command(OnLoginClicked);
        }

        private async void OnLoginClicked(object obj)
        {
            if (String.IsNullOrEmpty(Username) || String.IsNullOrEmpty(Password))
            {
                await DependencyService.Get<IDisplayAlert>().DisplayAlertAsync("Login Error", "Username or password cannot be empty", "Cancel");
                return;
            }

            try
            {
                CoreApp.StartSession(Username, Password, null);
            }
            catch (Exception e)
            {
                await DependencyService.Get<IDisplayAlert>().DisplayAlertAsync("Login Error", $"Login has an error occurred, code = {e}", "Cancel");
                return;
            }

            await Shell.Current.GoToAsync($"//{nameof(TaskListItemsPage)}");
        }
    }
}
