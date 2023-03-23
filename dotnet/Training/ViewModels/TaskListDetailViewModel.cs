using System;
using Training.Data;
using Training.Models;
using Training.Services;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(ListItemId), nameof(ListItemId))]
    public class TaskListDetailViewModel : BaseViewModel
    {
        private bool _isEditing;
        private string _toJSONString;
        private string _id;
        private string _taskListName;
        private TaskListItem _taskListItem = new TaskListItem();

        public string ListItemId 
        {
            get => _id;
            set
            {
                if (_id == value)
                    return;

                _id = value;
                if (!String.IsNullOrEmpty(ListItemId))
                {
                    IsEditing = true;
                    _taskListItem = DataStore.GetItemAsync(ListItemId).Result;
                    TaskListName = _taskListItem.Name;
                    using (var doc = CoreApp.Database.GetCollection(TodoDataStore.TaskListCollection).GetDocument(ListItemId))
                    {
                        ToJSONString = doc.ToJSON();
                    }
                }
            }
        }

        public string TaskListName
        {
            get => _taskListName;
            set
            {
                SetProperty(ref _taskListName, value);
                _taskListItem.Name = _taskListName;
            }
        }

        public bool IsEditing
        {
            get => _isEditing;
            set
            {
                SetProperty(ref _isEditing, value);
                if(_isEditing)
                    Title = "Edit Task List";
                else
                    Title = "New Task List";
            }
        }

        public string ToJSONString 
        {
            get => _toJSONString;
            set => SetProperty(ref _toJSONString, value);
        }

        public Command SaveCommand { get; }
        public Command CancelCommand { get; }

        public TaskListDetailViewModel()
        {
            SaveCommand = new Command(OnSave, ValidateSave);
            CancelCommand = new Command(OnCancel);
            this.PropertyChanged +=
                (_, __) => SaveCommand.ChangeCanExecute();
        }

        private bool ValidateSave()
        {
            return !String.IsNullOrWhiteSpace(TaskListName);
        }

        private async void OnCancel()
        {
            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }

        private async void OnSave()
        {
            if (IsEditing)
            {
                await DataStore.UpdateItemAsync(_taskListItem);
            }
            else
            {
                var res = await DataStore.AddItemAsync(_taskListItem);
                if(res != null)
                {
                    await DependencyService.Get<IDisplayAlert>().DisplayAlertAsync("Add Error", $"Couldn't add task list {_taskListItem.Name}: {res}", "OK");
                }
            }

            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }
    }
}
