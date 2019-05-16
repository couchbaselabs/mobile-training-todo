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
using Prototype.Mvvm.Input;
using Prototype.Mvvm.Services;
using Training.Models;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for an entry in the 
    /// </summary>
    public sealed class UserCellModel : BaseNavigationViewModel<UserModel>
    {

        #region Variables

        public delegate void StatusUpdatedEventHandler(object sender, State state);
        public event StatusUpdatedEventHandler StatusUpdated;

        #endregion

        #region Properties

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
        public UserCellModel(INavigationService navigation,
                             IUserDialogs dialogs,
                             string documentID) 
            : base(navigation, dialogs, new UserModel(documentID))
        {
            Dialogs = dialogs;
            DocumentID = documentID;
        }

        #endregion

        #region Private API

        private void Delete()
        {
            try {
                Model.Delete();
            } catch(Exception e) {
                Dialogs.Toast(e.Message);
            }
            StatusUpdated?.Invoke(this, State.DELETED);
        }

        #endregion

    }
}

