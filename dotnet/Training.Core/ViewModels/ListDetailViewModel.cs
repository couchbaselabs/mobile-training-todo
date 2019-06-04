//
// ListDetailViewModel.cs
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
using Acr.UserDialogs;
using Robo.Mvvm.Input;
using Robo.Mvvm.Services;

using System;
using System.ComponentModel;
using System.Threading.Tasks;
using System.Windows.Input;
using Training.Core;
using Training.Models;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for the task list / users tabbed view of the application
    /// </summary>
    public class ListDetailViewModel : BaseCollectionViewModel<ListDetailModel>, IDisposable
    {
        #region constants

        String[] TabNames = new string[] { "Tasks", "Users" };

        #endregion

        #region Properties

        INavigationService Navigation { get; set; }

        /// <summary>
        /// Gets or sets whether the current user has moderator status
        /// </summary>
        /// <value><c>true</c> if the user has moderator status; otherwise, <c>false</c>.</value>
        public bool HasModeratorStatus
        {
            get {
                return _hasModeratorStatus;
            }
            set {
                SetPropertyChanged(ref _hasModeratorStatus, value);
            }
        }
        private bool _hasModeratorStatus;

        
        public string SwitchTabText
        {
            get {
                return _switchTabText;
            }
            set {
                SetPropertyChanged(ref _switchTabText, value);
            }
        }
        private string _switchTabText = "Users";

        /// <summary>
        /// Gets the title of the page
        /// </summary>
        /// <value>The page title.</value>
        public string PageTitle
        {
            get {
                return _pageTitle;
            }
            set {
                SetPropertyChanged(ref _pageTitle, value);
            }
        }
        private string _pageTitle = "Tasks";

        internal string CurrentListID
        {
            get; set;
        }

        internal string Username
        {
            get; set;
        }

        public ICommand AddCommand => new Command(async () => await AddNewItem());

        public ICommand BackCommand => new Command(async () => { await Navigation.PopModalAsync(); });

        public ICommand SwitchCommand
        {
            get {
                if (_switchCommand == null) {
                    _switchCommand = new Command(SwitchSelected);
                }

                return _switchCommand;
            }
        }
        ICommand _switchCommand;

        #endregion

        #region Public API

        /// <summary>
        /// Initializes the view model with data passed to it
        /// </summary>
        /// <param name="username">The username of the current user.</param>
        /// <param name="name">The name of the task.</param>
        /// <param name="listID">The task document ID.</param>
        public void Init(string username, string name, string listID, 
            INavigationService navigation)
        {
            Navigation = navigation;
            Username = username;
            CurrentListID = listID;
            Model = new ListDetailModel(listID);
            CalculateModeratorStatus();

            var taskVM = GetViewModel<TasksViewModel>();
            taskVM.Init(CurrentListID);
            ViewModels.Add(taskVM);

            if (!HasModeratorStatus)
            {
                PropertyChanged += AddUsersTab;
            }
            else
            {
                AddUserPage();
            }
            SelectedViewModel = ViewModels[0];
        }

        #endregion

        #region Private API

        async Task AddNewItem()
        {
            if (SelectedIndex == 0)
                ((TasksViewModel)SelectedViewModel).AddCommand.Execute(new object());
            else
                ((UsersViewModel)SelectedViewModel).AddCommand.Execute(new object());
        }

        void SwitchSelected()
        {
            var newIndex = SelectedIndex == 0 ? 1 : 0;
            SwitchTabText = TabNames[SelectedIndex];
            PageTitle = TabNames[newIndex];
            SelectedViewModel = ViewModels[newIndex];
            SelectedIndex = newIndex;
        }

        private void AddUserPage()
        {
            var userVM = GetViewModel<UsersViewModel>();
            userVM.Init(CurrentListID);
            ViewModels.Add(userVM);
        }

        private void AddUsersTab(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(HasModeratorStatus))
            {
                if (HasModeratorStatus && ViewModels.Count < 2)
                {
                    AddUserPage();
                }
            }
        }

        private void CalculateModeratorStatus()
        {
            var owner = Model.Owner;
            if (Username.Equals(owner) || Model.HasModerator(Username)) {
                HasModeratorStatus = true;
                return;
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

