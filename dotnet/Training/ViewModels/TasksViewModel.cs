using System.Windows.Input;
using Training.Models;
using Training.Services;
using Training.Views;

namespace Training.ViewModels
{
    public class TasksViewModel : BaseViewModel
    {
        public Command LoadItemsCommand { get; }
        public Command AddItemCommand { get; }
        public Command<TaskItem> ItemTapped { get; }
        public Command<TaskItem> ItemSwiped { get; }
        public Command<TaskItem> ItemImageTapped { get; }



        public ICommand ToJSONCommand => new Command(OnToJSON);

        public TasksViewModel()
        {
            Title = "Tasks";
            //LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
            ItemTapped = new Command<TaskItem>(OnItemSelected);
            ItemSwiped = new Command<TaskItem>(OnItemSwiped);
            ItemImageTapped = new Command<TaskItem>(OnItemImageTapped);
            AddItemCommand = new Command(OnAddItem);
        }

        //private async Task ExecuteLoadItemsCommand()
        //{
        //    IsBusy = true;
            
        //    try
        //    {
        //        Tasks.Clear();
        //        var items = await TasksDataStore.GetItemsAsync(true);
        //        foreach (var i in items)
        //        {
        //            Tasks.Add(i.Value);
        //        }
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
            await Shell.Current.GoToAsync($"{nameof(TaskDetailPage)}");
        }

        private async void OnItemSelected(TaskItem item)
        {
            if (item == null)
                return;

            //This will push the TaskItemsPage onto the navigation stack
            await Shell.Current.GoToAsync($"{nameof(TaskDetailPage)}?{nameof(TaskDetailViewModel.TaskId)}={item.DocumentID}");
        }

        private async void OnItemSwiped(TaskItem item)
        {
            if (item == null)
                return;

            var selection = await DependencyService.Get<IDisplayAlert>().DisplayActionSheetAsync("Edit or Delete", "Cancel", null, "Edit", "Delete");
            if (selection == "Edit")
            {
                await Shell.Current.GoToAsync($"{nameof(TaskDetailPage)}?{nameof(TaskDetailViewModel.TaskId)}={item.DocumentID}");
            }
            else if (selection == "Delete")
            {
                await TasksDataStore.DeleteItemAsync(item.DocumentID);
                //await ExecuteLoadItemsCommand();
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

        private async void OnToJSON()
        {
            string jsonStr = "";
            var jsons = TasksDataStore.GetJson();
            foreach (var json in jsons) {
                jsonStr += json + "\n";
            }

            await Shell.Current.GoToAsync($"{nameof(ToJSONPage)}?{nameof(ToJSONViewModel.JSONString)}={jsonStr}");
        }
    }
}
