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
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using Training.Core;

namespace Training
{
    /// <summary>
    /// The view model for the list of task lists page
    /// </summary>
    public class TaskListsViewModel : BaseViewModel<TaskListsModel>
    {
        private readonly IUserDialogs _dialogs;

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
                if(SetProperty(ref _searchTerm, value)) {
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
                SetProperty(ref _selectedItem, null); // No "selection" effect
                if(value != null) {
                    ShowViewModel<ListDetailViewModel>(new { username = Model.Username, name = value.Name, listID = value.DocumentID });
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
        public ICommand AddCommand
        {
            get {
                return new MvxCommand(AddNewItem);
            }
        }

        /// <summary>
        /// Constructor, not to be called directly.
        /// </summary>
        /// <param name="dialogs">The interface responsible for displaying dialogs (from IoC container)</param>
        public TaskListsViewModel(IUserDialogs dialogs)
        {
            _dialogs = dialogs;
        }

        /// <summary>
        /// Initializes the view model with data passed to it
        /// </summary>
        /// <param name="username">The name of the current user.</param>
        /// <param name="loginEnabled">If set to <c>true</c> login is enabled in the application</param>
        public void Init(string username, bool loginEnabled)
        {
            if(String.IsNullOrEmpty(username)) {
                username = "todo";
            }

            Model = new TaskListsModel(username);
            LoginEnabled = loginEnabled;
            TaskLists.CollectionChanged += (sender, e) => 
            {
                if(e.NewItems == null) {
                    return;
                }

                foreach(TaskListCellModel item in e.NewItems) {
                    item.EditCommand = new MvxAsyncCommand<string>(Edit);
                }
            };
        }

        private void AddNewItem()
        {
            _dialogs.Prompt(new PromptConfig {
                OnAction = CreateNewItem,
                Title = "New Task List",
                Placeholder = "List Name"
            });
        }

        private void CreateNewItem(PromptResult result)
        {
            if(!result.Ok) {
                return;
            }

            try {
                Model.CreateTaskList(result.Text);
            } catch(Exception e) {
                _dialogs.ShowError(e.Message);
            }
        }

        private async Task Edit(string documentID)
        {
            var result = await _dialogs.PromptAsync(new PromptConfig {
                Title = "Edit Task List",
                Placeholder = "List Name"
            });

            if(result.Ok) {
                try {
                    Model.EditTaskList(documentID, result.Text);
                } catch(Exception e) {
                    _dialogs.ShowError(e.Message);
                }
            }
        }
    }
}

