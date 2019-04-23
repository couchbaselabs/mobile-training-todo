//
// TaskListsViewModel.cs
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
using System.Windows.Input;

using Acr.UserDialogs;
using CouchbaseLabs.MVVM.Input;
using CouchbaseLabs.MVVM.Services;
using Training.Core;
using Training.Models;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for the list of task lists page
    /// </summary>
    public class TaskListsViewModel : BaseNavigationViewModel
    {

        #region Variables

        private readonly IUserDialogs _dialogs;

        #endregion

        #region Properties

        public TaskListsModel Model { get; set; }

        /// <summary>
        /// Gets whether or not login is enabled
        /// </summary>
        public bool LoginEnabled
        {
            get; private set;
        }

        /// <summary>
        /// Gets or sets the current text being searched for in the list
        /// </summary>
        public string SearchTerm
        {
            get {
                return _searchTerm;
            }
            set {
                if(SetPropertyChanged(ref _searchTerm, value)) {
                    Model.Filter(value);
                }
            }
        }
        private string _searchTerm;

        /// <summary>
        /// Gets or sets the currently selected item in the page list
        /// </summary>
        /// <value>The selected item.</value>
        public TaskListCellModel SelectedItem
        {
            get {
                return _selectedItem;
            }
            set {
                _selectedItem = value;
                SetPropertyChanged(ref _selectedItem, null); // No "selection" effect
                if(value != null) {
                    //ShowViewModel<ListDetailViewModel>(new { username = Model.Username, name = value.Name, listID = value.DocumentID });
                }
            }
        }
        private TaskListCellModel _selectedItem;

        /// <summary>
        /// Gets the list of task lists for display in the list view
        /// </summary>
        public ObservableCollection<TaskListCellModel> TaskLists
        {
            get {
                return Model.TasksList;
            }
        }

        /// <summary>
        /// Gets the command that is fired when the add button is pressed
        /// </summary>
        public ICommand AddCommand => new Command(() => AddNewItem());

        public ICommand LogoutCommand => new Command(() => Logout());

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor, not to be called directly.
        /// </summary>
        /// <param name="dialogs">The interface responsible for displaying dialogs (from IoC container)</param>
        public TaskListsViewModel(INavigationService navigationService, IUserDialogs dialogs) : base(navigationService, dialogs)
        {
            _dialogs = dialogs;
            Model = new TaskListsModel(_dialogs);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Initializes the view model with data passed to it
        /// </summary>
        /// <param name="loginEnabled">If set to <c>true</c> login is enabled in the application</param>
        public void Init(bool loginEnabled)
        {
            LoginEnabled = loginEnabled;
        }

        //public void TestConflict()
        //{
        //    Model.TestConflict();
        //}

        #endregion

        #region Private API

        private void AddNewItem()
        {
            _dialogs.Prompt(new PromptConfig {
                OnAction = CreateNewItem,
                Title = "New Task List",
                Placeholder = "List Name"
            });
        }

        private void Logout()
        {
            CoreApp.EndSession();
            //ViewModel.Dispose();
            //Close(this);
        }

        private void CreateNewItem(PromptResult result)
        {
            if(!result.Ok) {
                return;
            }

            try {
                Model.CreateTaskList(result.Text);
            } catch(Exception e) {
                _dialogs.Toast(e.Message);
            }
        }

        #endregion

    }
}

