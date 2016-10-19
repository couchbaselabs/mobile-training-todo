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
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;

namespace Training.Core
{
    /// <summary>
    /// The view model for an entry in the 
    /// </summary>
    public sealed class UserCellModel : BaseViewModel<UserModel>
    {

        #region Variables

        private IUserDialogs _dialogs = Mvx.Resolve<IUserDialogs>();

        #endregion

        #region Properties

        /// <summary>
        /// Gets the handler for a delete request
        /// </summary>
        public ICommand DeleteCommand
        {
            get {
                return new MvxCommand(Delete);
            }
        }

        /// <summary>
        /// Gets the name of the user
        /// </summary>
        public string Name 
        {
            get {
                return Model.Name;
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentID">The ID of the document containing the user information</param>
        public UserCellModel(string documentID) : base(new UserModel(documentID))
        {
        }

        #endregion

        #region Private API

        private void Delete()
        {
            try {
                Model.Delete();
            } catch(Exception e) {
                _dialogs.ShowError(e.Message);
            }
        }

        #endregion

    }
}

