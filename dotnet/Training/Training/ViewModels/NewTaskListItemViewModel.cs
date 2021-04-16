using System;
using Training.Models;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(ListItemId), nameof(ListItemId))]
    [QueryProperty(nameof(TaskItemName), nameof(TaskItemName))]
    [QueryProperty(nameof(IsEditing), nameof(IsEditing))]
    public class NewTaskListItemViewModel : BaseViewModel
    {
        private string _listItemId;
        private string _taskItemName;
        private string _toJSONString;
        private bool _isEditing;
        public bool IsEditing 
        {
            get => _isEditing;
            set => SetProperty(ref _isEditing, value);
        }

        public string ListItemId
        {
            get { return _listItemId; }

            set
            {
                _listItemId = value;
                if (!String.IsNullOrEmpty(ListItemId))
                {
                    using (var doc = CoreApp.Database.GetDocument(ListItemId))
                    {
                        ToJSONString = doc.ToJSON();
                    }
                }
            }
        }
        public string TaskItemName
        {
            get => _taskItemName;
            set => SetProperty(ref _taskItemName, value);
        }

        public string ToJSONString 
        {
            get => _toJSONString;
            set => SetProperty(ref _toJSONString, value);
        }

        public Command SaveCommand { get; }
        public Command CancelCommand { get; }

        public NewTaskListItemViewModel()
        {
            SaveCommand = new Command(OnSave, ValidateSave);
            CancelCommand = new Command(OnCancel);
            this.PropertyChanged +=
                (_, __) => SaveCommand.ChangeCanExecute();
        }

        private bool ValidateSave()
        {
            return !String.IsNullOrWhiteSpace(_taskItemName);
        }

        private async void OnCancel()
        {
            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }

        private async void OnSave()
        {
            TaskListItem item = new TaskListItem()
            {
                Name = TaskItemName
            };

            if (IsEditing)
            {
                item.DocumentID = ListItemId;
                await DataStore.UpdateItemAsync(item);
            }
            else
            {
                await DataStore.AddItemAsync(item);
            }

            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }
    }
}
