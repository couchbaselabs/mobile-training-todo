using Couchbase.Lite;
using System;
using System.IO;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(TaskListId), nameof(TaskListId))]
    [QueryProperty(nameof(TaskId), nameof(TaskId))]
    [QueryProperty(nameof(IsNew), nameof(IsNew))]
    public class TaskDetailViewModel : BaseViewModel
    {
        private Database _db = CoreApp.Database;
        private string _taskItemName;
        private string _toJSONString;
        private bool _isNew;
        private string _taskId;
        private TaskItem _taskItem = new TaskItem();

        public string TaskListId { get; set; }

        public TaskItem TaskItem
        {
            get => _taskItem;
            set => SetProperty(ref _taskItem, value);
        }

        public string TaskId
        {
            get => _taskId;
            set
            {
                if (SetProperty(ref _taskId, value))
                {
                    _taskItem.DocumentID = _taskId;
                    _taskItem.TaskListID = TaskListId;
                    using (var d = _db.GetDocument(_taskId))
                    {
                        if (d == null)
                        {
                            return;
                        }

                        TaskItemName = _taskItem.Name = d.GetString("task");
                        _taskItem.IsChecked = d.GetBoolean("complete");
                        _taskItem.Thumbnail = d.GetBlob("image")?.Content;
                    }
                }
            }
        }

        public bool IsNew
        {
            get => _isNew;
            set
            {
                SetProperty(ref _isNew, value);
                if (_isNew)
                    Title = "New Task";
                else
                    Title = "Edit Task";
            }
        }

        public string TaskItemName
        {
            get => _taskItemName;
            set
            {
                SetProperty(ref _taskItemName, value);
                _taskItem.Name = _taskItemName;
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
                _taskItem.Thumbnail = null;
            }
        }

        private async void OnSave()
        {
            if (IsNew)
            {
                await TasksDataStore.AddItemAsync(_taskItem);
            }
            else
            {
                await TasksDataStore.UpdateItemAsync(_taskItem);
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
                _taskItem.Thumbnail = memoryStream.ToArray();
            }
        }
    }
}
