//
// ListDetailPage.xaml.cs
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
using System.ComponentModel;

using Training.Core;
using Training.Forms;
using Xamarin.Forms;

namespace Training
{
    /// <summary>
    /// The high level page containing a list of tasks and list of users
    /// </summary>
    public partial class ListDetailPage : TabbedPage
    {

        #region Variables

        private NavigationLifecycleHelper _navHelper;
        private UsersPage _usersPage;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        public ListDetailPage()
        {
            InitializeComponent();
            _navHelper =  new NavigationLifecycleHelper(this);
        }

        #endregion

        #region Private API

        private void AddUsersTab(object sender, PropertyChangedEventArgs e)
        {
            var viewModel = BindingContext as ListDetailViewModel;
            if(viewModel == null) {
                return;
            }

            if(e.PropertyName == nameof(viewModel.HasModeratorStatus)) {
                if(viewModel.HasModeratorStatus && Children.Count < 2) {
                    Children.Add(_usersPage);
                }
            }
        }

        #endregion

        #region Overrides

        protected override void OnBindingContextChanged()
        {
            base.OnBindingContextChanged();

            var viewModel = BindingContext as ListDetailViewModel;
            if(viewModel == null || Children.Count > 0) {
                return;
            }

            var child1 = new TasksPage();
            child1.BindingContext = new TasksViewModel(viewModel);
            Children.Add(child1);

            _usersPage = new UsersPage();
            _usersPage.BindingContext = new UsersViewModel(viewModel);

            if(!viewModel.HasModeratorStatus) {
                viewModel.PropertyChanged += AddUsersTab;
            } else {
                Children.Add(_usersPage);
            }
        }

        protected override void OnDisappearing()
        {
            if(_navHelper.OnDisappearing(Navigation)) {
                (Children[0].BindingContext as IDisposable)?.Dispose();
                (_usersPage.BindingContext as IDisposable)?.Dispose();
            }
        }

        #endregion

    }
}

