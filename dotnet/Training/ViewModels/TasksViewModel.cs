using MvvmHelpers;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;
using Training.Views;
using Xamarin.Forms;

namespace Training.ViewModels
{
    public class TasksViewModel : BaseViewModel
    {
        public ObservableRangeCollection<TaskItem> Tasks { get; } = new ObservableRangeCollection<TaskItem>();
        public Command LoadItemsCommand { get; }
        public Command AddItemCommand { get; }
        public Command<TaskItem> ItemTapped { get; }
        public Command<TaskItem> ItemSwiped { get; }
        public Command<TaskItem> ItemImageTapped { get; }

        public TasksViewModel()
        {
            Title = "Tasks";
            TasksDataStore.DataHasChanged += DataStore_DataHasChanged;
            LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
            ItemTapped = new Command<TaskItem>(OnItemSelected);
            ItemSwiped = new Command<TaskItem>(OnItemSwiped);
            ItemImageTapped = new Command<TaskItem>(OnItemImageTapped);
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
                Tasks.Clear();
                var items = await TasksDataStore.GetItemsAsync(true);
                foreach (var item in items)
                {
                    Tasks.Add(item);
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
            await Shell.Current.GoToAsync($"{nameof(TaskDetailPage)}?{nameof(TaskDetailViewModel.TaskListId)}={id}&{nameof(TaskDetailViewModel.IsNew)}={true}");
        }

        private async void OnItemSelected(TaskItem item)
        {
            if (item == null)
                return;

            //This will push the TaskItemsPage onto the navigation stack
            await Shell.Current.GoToAsync($"{nameof(TaskDetailPage)}?{nameof(TaskDetailViewModel.TaskId)}={item.DocumentID}&{nameof(TaskDetailViewModel.IsNew)}={false}");
        }

        private async void OnItemSwiped(TaskItem item)
        {
            if (item == null)
                return;

            var selection = await DependencyService.Get<IDisplayAlert>().DisplayActionSheetAsync("Edit or Delete", "Cancel", null, "Edit", "Delete");
            if (selection == "Edit")
            {
                await Shell.Current.GoToAsync($"{nameof(TaskDetailPage)}?{nameof(TaskDetailViewModel.TaskId)}={item.DocumentID}&{nameof(TaskDetailViewModel.IsNew)}={false}");
            }
            else if (selection == "Delete")
            {
                await TasksDataStore.DeleteItemAsync(item.DocumentID);
                await ExecuteLoadItemsCommand();
            }
        }

        private async void OnItemImageTapped(TaskItem item)
        {
            if (item == null)
                return;

            await ExecuteImageChangedCommand(item);
        }

        async Task ExecuteImageChangedCommand(TaskItem item)
        {
            Stream stream = await DependencyService.Get<IPhotoPickerService>().GetImageStreamAsync();
            if (stream == null)
            {
                return;
            }

            using (var memoryStream = new MemoryStream())
            {
                stream.CopyTo(memoryStream);
                item.Thumbnail = memoryStream.ToArray();
                await TasksDataStore.UpdateItemAsync(item);
            }
        }
    }
}
