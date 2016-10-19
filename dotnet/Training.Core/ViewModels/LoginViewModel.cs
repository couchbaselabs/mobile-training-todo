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
using MvvmCross.Core.ViewModels;

namespace Training.Core
{
    public sealed class LoginViewModel : BaseViewModel<LoginModel>
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
            get {
                return _username;
            }
            set {
                SetProperty(ref _username, value);
            }
        }
        private string _username;

        /// <summary>
        /// Gets the command to execute for login
        /// </summary>
        public ICommand LoginCommand
        {
            get {
                return new MvxAsyncCommand<string>(Login);
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor (not to be called directly)
        /// </summary>
        /// <param name="dialogs">The interface controlling UI dialogs</param>
        public LoginViewModel(IUserDialogs dialogs) : base(new LoginModel())
        {
            _dialogs = dialogs;
        }

        #endregion

        #region Private API

        private async Task Login(string password)
        {
            if(String.IsNullOrWhiteSpace(Username) || String.IsNullOrWhiteSpace(password)) {
                _dialogs.ShowError("Username or password cannot be empty");
                return;
            }

            if(!LoginModel.IsValidUsername(Username)) {
                _dialogs.ShowError("Invalid username");
                return;
            }

            try {
                CoreApp.StartSession(Username, password, null);
            } catch(CouchbaseLiteException e) {
                if(e.CBLStatus.Code == StatusCode.Unauthorized) {
                    var result = await _dialogs.PromptAsync(new PromptConfig {
                        Title = "Password Changed",
                        OkText = "Migrate",
                        CancelText = "Delete",
                        IsCancellable = true,
                        InputType = Acr.UserDialogs.InputType.Password
                    });

                    if(result.Ok) {
                        CoreApp.StartSession(Username, result.Text, password);
                    } else {
                        Model.DeleteDatabase(Username);
                        Login(password);
                        return;
                    }
                } else {
                    _dialogs.ShowError($"Login has an error occurred, code = {e.CBLStatus.Code}");
                    return;
                }
            } catch(Exception e) {
                _dialogs.ShowError($"Login has an error occurred, code = {e}");
                return;
            }

            ShowViewModel<TaskListsViewModel>(new { loginEnabled = true });
        }

        #endregion
    }
}
