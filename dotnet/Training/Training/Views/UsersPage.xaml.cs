using System.Collections.Generic;
using System.Linq;
using Training.Models;
using Training.ViewModels;
using Xamarin.Forms;

namespace Training.Views
{
    public partial class UsersPage : ContentPage
    {
        public UsersPage()
        {
            InitializeComponent();
        }

        async void OnCollectionViewSelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            string userName = (e.CurrentSelection.FirstOrDefault() as User).Name;
            // The following route works because route names are unique in this application.
            //await Shell.Current.GoToAsync($"userdetails?name={userName}");
            // The full route is shown below.
            await Shell.Current.GoToAsync($"//TaskListItemsPage/TaskItemsPage/userdetails?name={userName}");
        }
    }
}
