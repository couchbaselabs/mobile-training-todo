using Training.Models;
using Training.Services;
using Training.Views;
using Xamarin.Forms;

namespace Training.ViewModels
{
    public class TaskListItemsViewModel : BaseViewModel
    {
        public Command AddItemCommand { get; }
        public Command ToJSONCommand { get; }
        public Command<TaskListItem> ItemTapped { get; }
        public Command<TaskListItem> ItemSwiped { get; }
        public Command LoadItemsCommand { get; }

        public TaskListItemsViewModel()
        {
            Title = "Task List";
            //LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
            ItemTapped = new Command<TaskListItem>(OnItemSelected);
            ItemSwiped = new Command<TaskListItem>(OnItemSwiped);
            AddItemCommand = new Command(OnAddItem);
            ToJSONCommand = new Command(OnToJSON);
        }

        //private async Task ExecuteLoadItemsCommand()
        //{
        //    IsBusy = true;

        //    try
        //    {
        //        //Items.Clear();
        //        //var items = await DataStore.GetItemsAsync(true);
        //        //foreach (var i in items)
        //        //{
        //        //    Items.Add(i.Value);
        //        //}
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
            await Shell.Current.GoToAsync($"{nameof(TaskListDetailPage)}");
        }

        private async void OnToJSON()
        {
            string jsonStr = "";
            var jsons = await DataStore.ReturnJsonsAsync(true);
            foreach (var json in jsons)
            {
                jsonStr += json + "\n";
            }

            await Shell.Current.GoToAsync($"{nameof(ToJSONPage)}?{nameof(ToJSONViewModel.JSONString)}={jsonStr}");
        }

        private async void OnItemSelected(TaskListItem item)
        {
            if (item == null)
                return;

            // This will push the TaskItemsPage onto the navigation stack
            await TasksDataStore.LoadItemsAsync(item.DocumentID);
            await UsersDataStore.LoadItemsAsync(item.DocumentID);
            await Shell.Current.GoToAsync("//taskListItem");

            // await Shell.Current.GoToAsync($"{nameof(TaskListItemPage)}?{nameof(TaskListItemViewModel.ListItemId)}={item.DocumentID}");
        }

        private async void OnItemSwiped(TaskListItem item)
        {
            if (item == null)
                return;

            var selection = await DependencyService.Get<IDisplayAlert>().DisplayActionSheetAsync("Edit or Delete", "Cancel", null, "Edit", "Delete");
            if (selection == "Edit")
            {
                await Shell.Current.GoToAsync($"{nameof(TaskListDetailPage)}?{nameof(TaskListDetailViewModel.ListItemId)}={item.DocumentID}");
            }
            else if (selection == "Delete")
            {
                await DataStore.DeleteItemAsync(item.DocumentID);
                //await ExecuteLoadItemsCommand();
            }
        }
    }
}