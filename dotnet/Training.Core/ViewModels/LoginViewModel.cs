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
using System.Windows.Input;

using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;

namespace Training.Core
{
    public sealed class LoginViewModel : BaseViewModel<LoginModel>
    {
        private readonly IUserDialogs _dialogs;

        private string _username;
        public string Username
        {
            get {
                return _username;
            }
            set {
                SetProperty(ref _username, value);
            }
        }

        private string _password;
        public string Password
        {
            get {
                return _password;
            }
            set {
                SetProperty(ref _password, value);
            }
        }

        public ICommand LoginCommand
        {
            get {
                return new MvxCommand(Login);
            }
        }

        public LoginViewModel(IUserDialogs dialogs)
        {
            _dialogs = dialogs;
        }

        private void Login()
        {
            if(String.IsNullOrWhiteSpace(Username) || String.IsNullOrWhiteSpace(Password)) {
                _dialogs.ShowError("Username or password cannot be empty");
                return;
            }

            if(!LoginModel.IsValidUsername(Username)) {
                _dialogs.ShowError("Invalid username");
                return;
            }

            ShowViewModel<TaskListsViewModel>(new { loginEnabled = true, username = Username, password = Password });
        }
    }
}
