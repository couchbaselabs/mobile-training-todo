using Couchbase.Lite;
using System;
using System.Collections.Generic;
using System.Text;
using Training.Models;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(TaskListId), nameof(TaskListId))]
    [QueryProperty(nameof(UserId), nameof(UserId))]
    [QueryProperty(nameof(IsEditing), nameof(IsEditing))]
    public class UserDetailViewModel : BaseViewModel
    {
        private Database _db = CoreApp.Database;
        private string _userId;
        private string _userName;
        private string _toJSONString;
        private bool _isEditing;
        private User _user = new User();

        public string TaskListId { get; set; }

        public User User
        {
            get => _user;
            set { SetProperty(ref _user, value); }
        }

        public bool IsEditing
        {
            get => _isEditing;
            set
            {
                SetProperty(ref _isEditing, value);
                if (_isEditing)
                    Title = "Edit User";
                else
                    Title = "New User";
            }
        }

        public string UserId
        {
            get { return _userId; }

            set
            {
                if (SetProperty(ref _userId, value))
                {
                    _user.DocumentID = _userId;
                    _user.TaskListID = TaskListId;
                    using (var d = _db.GetDocument(_userId))
                    {
                        if (d == null)
                        {
                            return;
                        }

                        UserName = _user.Name = d.GetString("username");
                    }
                }
            }
        }

        public string UserName
        {
            get => _userName;
            set 
            { 
                SetProperty(ref _userName, value);
                _user.Name = _userName;
            }
        }

        public string ToJSONString
        {
            get => _toJSONString;
            set => SetProperty(ref _toJSONString, value);
        }

        public Command SaveCommand { get; }
        public Command CancelCommand { get; }

        public UserDetailViewModel()
        {
            SaveCommand = new Command(OnSave, ValidateSave);
            CancelCommand = new Command(OnCancel);
            this.PropertyChanged +=
                (_, __) => SaveCommand.ChangeCanExecute();
        }

        private bool ValidateSave()
        {
            return !String.IsNullOrWhiteSpace(_userName);
        }

        private async void OnCancel()
        {
            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }

        private async void OnSave()
        {
            User user = new User()
            {
                Name = UserName
            };

            if (IsEditing)
            {
                user.DocumentID = UserId;
                await UsersDataStore.UpdateItemAsync(user);
            }
            else
            {
                await UsersDataStore.AddItemAsync(user);
            }

            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }
    }
}
