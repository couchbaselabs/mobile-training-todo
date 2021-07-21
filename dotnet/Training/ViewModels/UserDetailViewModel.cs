using Couchbase.Lite;
using System;
using System.Collections.Generic;
using System.Text;
using Training.Models;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(UserId), nameof(UserId))]
    public class UserDetailViewModel : BaseViewModel
    {
        private Database _db = CoreApp.Database;
        private string _id;
        private string _userName;
        private string _toJSONString;
        private bool _isEditing;
        private User _user = new User();

        public User User
        {
            get => _user;
            set => SetProperty(ref _user, value);
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
            get { return _id; }

            set
            {
                if (_id == value)
                    return;

                _id = value;
                if (!String.IsNullOrEmpty(_id))
                {
                    IsEditing = true;
                    User = UsersDataStore.GetItemAsync(_id).Result;
                    UserName = User.Name;
                    using (var d = _db.GetDocument(_id))
                    {
                        ToJSONString = d.ToJSON();
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
                User.Name = _userName;
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
