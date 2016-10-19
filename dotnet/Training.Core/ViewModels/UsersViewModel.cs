//
// UsersViewModel.cs
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
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;

namespace Training.Core
{
    /// <summary>
    /// The view model for the users page
    /// </summary>
    public class UsersViewModel : BaseViewModel<UsersModel>, IDisposable
    {

        #region Variables

        private IUserDialogs _dialogs;

        #endregion

        #region Properties

        /// <summary>
        /// Gets or sets the current text being searched for in the list
        /// </summary>
        public string SearchTerm
        {
            get {
                return _searchTerm;
            }
            set {
                if(SetProperty(ref _searchTerm, value)) {
                    Model.Filter(value);
                }
            }
        }
        private string _searchTerm;

        /// <summary>
        /// Gets the handler for an add request
        /// </summary>
        public ICommand AddCommand
        {
            get {
                return new MvxAsyncCommand(AddNewUser);
            }
        }

        /// <summary>
        /// Gets the current list of users for the list
        /// </summary>
        /// <value>The list data.</value>
        public ObservableCollection<UserCellModel> ListData
        {
            get {
                return Model.ListData;
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="parent">The parent view model (this is a nested view model).</param>
        public UsersViewModel(ListDetailViewModel parent) : base(new UsersModel(parent.CurrentListID))
        {
            _dialogs = Mvx.Resolve<IUserDialogs>();
        }

        #endregion

        #region Private API

        private async Task AddNewUser()
        {
            var result = await _dialogs.PromptAsync(new PromptConfig {
                Title = "New User",
                Placeholder = "User Name"
            });

            if(result.Ok) {
                try {
                    Model.CreateNewUser(result.Text);
                } catch(Exception e) {
                    _dialogs.ShowError(e.Message);
                }
            }
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            Model.Dispose();
        }

        #endregion

    }
}

