using MvvmHelpers;
using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;
using Training.Views;
using Xamarin.Forms;

namespace Training.ViewModels
{
    public class UsersViewModel : BaseViewModel
    {
        public ObservableRangeCollection<User> Users { get; } = new ObservableRangeCollection<User>();
        public Command LoadItemsCommand { get; }
        public Command AddItemCommand { get; }
        public Command<User> ItemTapped { get; }
        public Command<User> ItemSwiped { get; }

        public UsersViewModel()
        {
            Title = "Users";
            UsersDataStore.DataHasChanged += DataStore_DataHasChanged;
            LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
            ItemTapped = new Command<User>(OnItemSelected);
            ItemSwiped = new Command<User>(OnItemSwiped);
            AddItemCommand = new Command(async (object id) => await OnAddItem(id));
        }

        private void DataStore_DataHasChanged(object sender, EventArgs e)
        {
            ExecuteLoadItemsCommand();
        }

        private async Task ExecuteLoadItemsCommand()
        {
            IsBusy = true;

            try
            {
                Users.Clear();
                var items = await UsersDataStore.GetItemsAsync(true);
                foreach (var item in items)
                {
                    Users.Add(item);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex);
            }
            finally
            {
                IsBusy = false;
            }
        }

        public void OnAppearing()
        {
            IsBusy = true;
        }

        private async Task OnAddItem(object taskListId)
        {
            var id = taskListId as string;
            await Shell.Current.GoToAsync($"{nameof(UserDetailPage)}?{nameof(UserDetailViewModel.TaskListId)}={id}&{nameof(UserDetailViewModel.IsEditing)}={false}");
        }

        async void OnItemSelected(User user)
        {
            if (user == null)
                return;

            //This will push the TaskItemsPage onto the navigation stack
            await Shell.Current.GoToAsync($"{nameof(UserDetailPage)}?{nameof(UserDetailViewModel.UserId)}={user.DocumentID}&{nameof(UserDetailViewModel.IsEditing)}={true}");
        }

        async void OnItemSwiped(User user)
        {
            if (user == null)
                return;

            var selection = await DependencyService.Get<IDisplayAlert>().DisplayActionSheetAsync("Edit or Delete", "Cancel", null, "Edit", "Delete");
            if (selection == "Edit")
            {
                await Shell.Current.GoToAsync($"{nameof(UserDetailPage)}?{nameof(UserDetailViewModel.UserId)}={user.DocumentID}&{nameof(UserDetailViewModel.IsEditing)}={true}");
            }
            else if (selection == "Delete")
            {
                await UsersDataStore.DeleteItemAsync(user.DocumentID);
                await ExecuteLoadItemsCommand();
            }
        }
    }
}