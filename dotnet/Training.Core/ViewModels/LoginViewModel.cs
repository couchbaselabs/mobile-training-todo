//
// LoginViewModel.cs
//
// Author:
// 	Jim Borden  <jim.borden@couchbase.com>
//
// Copyright (c) 2016 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
using System;
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;

using Couchbase.Lite;
using Robo.Mvvm;
using Robo.Mvvm.Input;
using Robo.Mvvm.Services;
using Training.Core;

namespace Training.ViewModels
{
    public sealed class LoginViewModel : BaseNavigationViewModel
    {

        #region Variables 

        private readonly IUserDialogs _dialogs;

        #endregion

        #region Properties

        /// <summary>
        /// Gets or sets the username of the user currently trying to log in
        /// </summary>
        public string Username
        {
            get =>_username;
            set => SetPropertyChanged(ref _username, value);
        }
        private string _username;

        public string Password
        {
            get => _password;
            set => SetPropertyChanged(ref _password, value);
        }
        private string _password;

        /// <summary>
        /// Gets the command to execute for login
        /// </summary>
        public ICommand LoginCommand => new Command(async () => await Login());

        #endregion

        #region Constructors
        
        ///// <summary>
        ///// Constructor(not to be called directly)
        ///// </summary>
        ///// <param name = "dialogs" > The interface controlling UI dialogs</param>
        public LoginViewModel(INavigationService navigation, IUserDialogs dialogs) : base(navigation, dialogs)
        {
            _dialogs = dialogs;
        }

        #endregion

        #region Private API

        private async Task Login()
        {
            if(String.IsNullOrWhiteSpace(Username) || String.IsNullOrWhiteSpace(Password)) {
                _dialogs.Toast("Username or password cannot be empty");
                return;
            }

            if(!IsValidUsername(Username)) {
                _dialogs.Toast("Invalid username");
                return;
            }

            try {
                CoreApp.StartSession(Username, Password, null);
            } catch(Exception e) {
                _dialogs.Toast($"Login has an error occurred, code = {e}");
                return;
            }

            var vm = GetViewModel<TaskListsViewModel>();
            vm.Init(true);
            await Navigation.SetDetailAsync(vm);
        }

        /// <summary>
        /// Checks to see if a username is valid (i.e. can be used as a database name)
        /// </summary>
        /// <param name="username">The username to check</param>
        /// <returns><c>true</c> if the username is valid, <c>false</c> otherwise</returns>
        private bool IsValidUsername(string username)
        {
            return true;
        }

        /// <summary>
        /// Deletes a database by name (used in migration logic)
        /// </summary>
        /// <param name="dbName">The name of the database to delete</param>
        private void DeleteDatabase(string dbName)
        {
            Database.Delete(dbName, null);
        }

        #endregion
    }
}
