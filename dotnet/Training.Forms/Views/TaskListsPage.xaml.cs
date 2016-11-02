//
// TaskListsPage.xaml.cs
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

using Xamarin.Forms;

namespace Training
{
    /// <summary>
    /// The page that displays the list of task lists in a given database
    /// </summary>
    public partial class TaskListsPage : ContentPage
    {

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        public TaskListsPage()
        {
            InitializeComponent();
        }

        #endregion

        #region Overrides

        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            // To detect from the renderer that this page doesn't need
            // to process shakes
            IsVisible = false;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();

            // To detect from the renderer that this page needs to
            // to process shakes
            IsVisible = true;
        }

        protected override void OnBindingContextChanged()
        {
            base.OnBindingContextChanged();

            if(_logoutButton == null) {
                return;
            }

            var newContext = BindingContext as TaskListsViewModel;
            if(newContext == null) {
                return;
            }

            if(!newContext.LoginEnabled) {
                ToolbarItems.Remove(_logoutButton);
                _logoutButton = null;
            }
        }

        #endregion

    }
}

