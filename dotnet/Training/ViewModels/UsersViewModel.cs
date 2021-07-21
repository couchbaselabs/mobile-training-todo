using Training.Models;
using Training.Services;
using Training.Views;
using Xamarin.Forms;

namespace Training.ViewModels
{
    public class UsersViewModel : BaseViewModel
    {
        public Command LoadItemsCommand { get; }
        public Command AddItemCommand { get; }
        public Command<User> ItemTapped { get; }
        public Command<User> ItemSwiped { get; }

        public UsersViewModel()
        {
            Title = "Users";
            //LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
            ItemTapped = new Command<User>(OnItemSelected);
            ItemSwiped = new Command<User>(OnItemSwiped);
            AddItemCommand = new Command(OnAddItem);
        }

        //private async Task ExecuteLoadItemsCommand()
        //{
        //    IsBusy = true;

        //    try
        //    {
        //        Users.Clear();
        //        var items = await UsersDataStore.GetItemsAsync(true);
        //        Users.AddRange(items);
        //    }
        //    catch (Exception ex)
        //    {
        //        Debug.WriteLine(ex);
        //    }
        //    finally
        //    {
        //        IsBusy = false;
        //    }
        //}

        //public void OnAppearing()
        //{
        //    IsBusy = true;
        //}

        private async void OnAddItem()
        {
            await Shell.Current.GoToAsync($"{nameof(UserDetailPage)}");
        }

        async void OnItemSelected(User user)
        {
            if (user == null)
                return;

            //This will push the TaskItemsPage onto the navigation stack
            await Shell.Current.GoToAsync($"{nameof(UserDetailPage)}?{nameof(UserDetailViewModel.UserId)}={user.DocumentID}");
        }

        async void OnItemSwiped(User user)
        {
            if (user == null)
                return;

            var selection = await DependencyService.Get<IDisplayAlert>().DisplayActionSheetAsync("Edit or Delete", "Cancel", null, "Edit", "Delete");
            if (selection == "Edit")
            {
                await Shell.Current.GoToAsync($"{nameof(UserDetailPage)}?{nameof(UserDetailViewModel.UserId)}={user.DocumentID}");
            }
            else if (selection == "Delete")
            {
                await UsersDataStore.DeleteItemAsync(user.DocumentID);
                //await ExecuteLoadItemsCommand();
            }
        }
    }
}