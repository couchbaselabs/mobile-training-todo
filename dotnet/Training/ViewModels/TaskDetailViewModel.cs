using Couchbase.Lite;
using Training.Data;
using Training.Models;
using Training.Services;

namespace Training.ViewModels
{
    [QueryProperty(nameof(TaskId), nameof(TaskId))]
    public class TaskDetailViewModel : BaseViewModel
    {
        private Database _db = CoreApp.Database;
        private string _toJSONString;
        private bool _isEditing;
        private string _id;
        private string _taskItemName;
        private TaskItem _taskItem = new TaskItem();

        public TaskItem TaskItem
        {
            get => _taskItem;
            set => SetProperty(ref _taskItem, value);
        }

        public string TaskId
        {
            get => _id;
            set
            {
                if (_id == value)
                    return;

                _id = value;
                if (!String.IsNullOrEmpty(_id))
                {
                    IsEditing = true;
                    TaskItem = TasksDataStore.GetItemAsync(_id).Result;
                    TaskItemName = TaskItem.Name;
                    using (var d = _db.GetCollection(TasksData.TaskCollection).GetDocument(_id))
                    {
                        ToJSONString = d.ToJSON();
                    }
                }
            }
        }

        public bool IsEditing
        {
            get => _isEditing;
            set
            {
                SetProperty(ref _isEditing, value);
                if (_isEditing)
                    Title = "Edit Task";
                else
                    Title = "New Task";
            }
        }

        public string TaskItemName
        {
            get => _taskItemName;
            set
            {
                SetProperty(ref _taskItemName, value);
                TaskItem.Name = _taskItemName;
            }
        }

        public string ToJSONString
        {
            get => _toJSONString;
            set => SetProperty(ref _toJSONString, value);
        }

        public Command SaveCommand { get; }
        public Command CancelCommand { get; }
        public Command ImageTapped { get; }
        public Command ImageSwiped { get; }

        public TaskDetailViewModel()
        {
            SaveCommand = new Command(OnSave, ValidateSave);
            CancelCommand = new Command(OnCancel);
            ImageTapped = new Command(OnImageTapped);
            ImageSwiped = new Command(OnImageSwiped);
            this.PropertyChanged +=
                (_, __) => SaveCommand.ChangeCanExecute();
        }

        private bool ValidateSave()
        {
            return !String.IsNullOrWhiteSpace(TaskItemName);
        }

        private async void OnCancel()
        {
            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }

        private async void OnImageTapped()
        {
            await ExecuteImageChangedCommand();
        }

        private async void OnImageSwiped()
        {
            var selection = await DependencyService.Get<IDisplayAlert>().DisplayActionSheetAsync("Delete?", "Cancel", null, "Delete");
            if (selection == "Delete")
            {
                TaskItem.Thumbnail = null;
                await TasksDataStore.UpdateItemAsync(TaskItem);
            }
        }

        private async void OnSave()
        {
            if (IsEditing)
            {
                await TasksDataStore.UpdateItemAsync(TaskItem);
            }
            else
            {
                await TasksDataStore.AddItemAsync(TaskItem);
            }

            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }

        public async Task ExecuteImageChangedCommand()
        {
            Stream stream = await DependencyService.Get<IPhotoPickerService>().GetImageStreamAsync();
            if (stream == null)
            {
                return;
            }

            using (var memoryStream = new MemoryStream())
            {
                stream.CopyTo(memoryStream);
                TaskItem.Thumbnail = memoryStream.ToArray();
            }
        }
    }
}
