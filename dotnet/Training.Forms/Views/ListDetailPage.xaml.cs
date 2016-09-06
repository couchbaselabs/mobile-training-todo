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
    public partial class ListDetailPage : TabbedPage
    {
        private NavigationLifecycleHelper _navHelper;
        private UsersPage _usersPage;

        public ListDetailPage()
        {
            InitializeComponent();
            _navHelper =  new NavigationLifecycleHelper(this);
        }

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

        protected override void OnBindingContextChanged()
        {
            base.OnBindingContextChanged();

            var viewModel = BindingContext as ListDetailViewModel;
            if(viewModel == null) {
                return;
            }

            var child1 = (TasksPage)Children[0];
            child1.BindingContext = new TasksViewModel(viewModel);

            _usersPage = (UsersPage)Children[1];
            _usersPage.BindingContext = new UsersViewModel(viewModel);

            if(!viewModel.HasModeratorStatus) {
                Children.RemoveAt(1);
                viewModel.PropertyChanged += AddUsersTab;
            }
        }

        protected override void OnDisappearing()
        {
            if(_navHelper.OnDisappearing(Navigation)) {
                (Children[0].BindingContext as IDisposable)?.Dispose();
                (_usersPage.BindingContext as IDisposable)?.Dispose();
            }
        }
    }
}

