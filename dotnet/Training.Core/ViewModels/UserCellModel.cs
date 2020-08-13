//
// UserCellModel.cs
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
using Robo.Mvvm;
using Robo.Mvvm.Input;
using Robo.Mvvm.Services;
using Training.Core;
using Training.Models;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for an entry in the 
    /// </summary>
    public sealed class UserCellModel : BaseNotify
    {

        #region Variables

        IUserDialogs _dialogs;

        #endregion

        #region Properties

        ObservableConcurrentDictionary<string, UserCellModel> _users;
        public ObservableConcurrentDictionary<string, UserCellModel> Users
        {
            get => _users;
            set => SetPropertyChanged(ref _users, value);
        }

        UserModel _user;
        public UserModel User
        {
            get => _user;
            set => SetPropertyChanged(ref _user, value);
        }

        /// <summary>
        /// Gets the handler for a delete request
        /// </summary>
        public ICommand DeleteCommand => new Command(() => Delete());

        /// <summary>
        /// Gets the name of the user
        /// </summary>
        public string Name
        {
            get => _name;
            set => SetPropertyChanged(ref _name, value);
        }
        string _name = "";

        /// <summary>
        /// Gets the document ID of the document being tracked
        /// </summary>
        public string DocumentID { get; set; }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentID">The ID of the document containing the user information</param>
        public UserCellModel(IUserDialogs dialogs, string documentID, ObservableConcurrentDictionary<string, UserCellModel> users) 
        {
            _dialogs = dialogs;
            DocumentID = documentID;
            User = new UserModel(DocumentID);
            Users = users;
        }

        #endregion

        #region Private API

        private void Delete()
        {
            try {
                User.Delete();
            } catch(Exception e) {
                _dialogs.Toast(e.Message);
                return;
            }
            Users.Remove(DocumentID);
        }

        #endregion

    }
}

