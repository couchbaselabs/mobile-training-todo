using System;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Threading.Tasks;
using Training.Models;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(ListItemId), nameof(ListItemId))]
    class TaskListItemViewModel : BaseViewModel
    {
        private string _listItemId;
        public string ListItemId
        {
            get
            {
                return _listItemId;
            }
            set
            {
                _listItemId = value;
                LoadItemId(value);
            }
        }

        public ObservableCollection<TaskItem> Tasks { get; set; }
        public ObservableCollection<User> Users { get; set; }

        public Command LoadItemsCommand { get; }

        public TaskListItemViewModel()
        {
            LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
        }

        public async void LoadItemId(string itemId)
        {
            try
            {
                var item = await DataStore.GetItemAsync(itemId);
                Tasks = item.Tasks;
                Users = item.Users;
            } catch (Exception) {
                Debug.WriteLine("Failed to Load Item");
            }
        }

        async Task ExecuteLoadItemsCommand()
        {
            IsBusy = true;

            try
            {
                Tasks.Clear();
                Users.Clear();
                var item = await DataStore.GetItemAsync(_listItemId);
                Tasks = item.Tasks;
                Users = item.Users;
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
    }
}
