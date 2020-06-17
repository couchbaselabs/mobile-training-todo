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
using Robo.Mvvm.Forms.Pages;
using System.ComponentModel;
using Training.ViewModels;

using Xamarin.Forms.Xaml;

namespace Training.Views
{

    /// <summary>
    /// The high level page containing a list of tasks and list of users
    /// </summary>
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class ListDetailPage : BaseTabbedPage<ListDetailViewModel>
    {

        #region Variables

        private NavigationLifecycleHelper _navHelper;

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

        #region Overrides

        protected override void OnDisappearing()
        {
            //if (_navHelper.OnDisappearing(Navigation)) {
            //    ((Children[0] as MvxPage)?.ViewModel as IDisposable)?.Dispose();
            //    (_usersPage.ViewModel as IDisposable)?.Dispose();
            //}
        }

        #endregion

    }
}

