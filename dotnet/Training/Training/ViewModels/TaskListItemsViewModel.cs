using System;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;
using Training.Views;
using Xamarin.Forms;

namespace Training.ViewModels
{
    public class TaskListItemsViewModel : BaseViewModel
    {
        private TaskListItem _selectedItem;

        public ObservableCollection<TaskListItem> Items { get; set; }
        public Command LoadItemsCommand { get; }
        public Command AddItemCommand { get; }
        public Command ToJSONCommand { get; }
        public Command<TaskListItem> ItemTapped { get; }
        public Command<TaskListItem> ItemSwiped { get; }

        public TaskListItemsViewModel()
        {
            Title = "Task List";
            var store = new TodoDataStore();
            Items = new ObservableCollection<TaskListItem>();
            LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
            ItemTapped = new Command<TaskListItem>(OnItemSelected);
            ItemSwiped = new Command<TaskListItem>(OnItemSwiped);
            AddItemCommand = new Command(OnAddItem);
            ToJSONCommand = new Command(OnToJSON);
        }

        async Task ExecuteLoadItemsCommand()
        {
            IsBusy = true;

            try
            {
                Items.Clear();
                var items = await DataStore.GetItemsAsync(true);
                foreach (var item in items)
                {
                    Items.Add(item);
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
            SelectedItem = null;
        }

        public TaskListItem SelectedItem
        {
            get => _selectedItem;
            set
            {
                SetProperty(ref _selectedItem, value);
                OnItemSelected(value);
            }
        }

        private async void OnAddItem(object obj)
        {
            await Shell.Current.GoToAsync($"{nameof(NewTaskListItemPage)}?{nameof(NewTaskListItemViewModel.IsEditing)}={false}");
        }

        private async void OnToJSON()
        {
            string jsonStr = "";
            var jsons = await DataStore.ReturnJsonsAsync(true);
            foreach(var json in jsons)
            {
                jsonStr += json + "\n";
            }

            await Shell.Current.GoToAsync($"{nameof(ToJSONPage)}?{nameof(ToJSONViewModel.JSONString)}={jsonStr}");
        }

        async void OnItemSelected(TaskListItem item)
        {
            if (item == null)
                return;

            // This will push the TaskItemsPage onto the navigation stack
            await Shell.Current.GoToAsync($"{nameof(TaskListItemPage)}?{nameof(TaskListItemViewModel.ListItemId)}={item.DocumentID}");
        }

        async void OnItemSwiped(TaskListItem item)
        {
            if (item == null)
                return;

            var selection = await DependencyService.Get<IDisplayAlert>().DisplayActionSheetAsync("Edit or Delete", "Cancel", null, "Edit", "Delete");
            if(selection == "Edit")
            {
                await Shell.Current.GoToAsync($"{nameof(NewTaskListItemPage)}?{nameof(NewTaskListItemViewModel.ListItemId)}={item.DocumentID}&{nameof(NewTaskListItemViewModel.TaskItemName)}={item.Name}&{nameof(NewTaskListItemViewModel.IsEditing)}={true}");
            }
            else if(selection == "Delete")
            {
                await DataStore.DeleteItemAsync(item.DocumentID);
                await ExecuteLoadItemsCommand();
            }
        }
    }
}