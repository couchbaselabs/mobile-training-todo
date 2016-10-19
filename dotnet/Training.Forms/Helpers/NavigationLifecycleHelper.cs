//
// NavigationLifecycleHelper.cs
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
using System.Linq;

using Xamarin.Forms;

namespace Training.Forms
{
    /// <summary>
    /// A helper class to dispose view models when a page disappears
    /// </summary>
    public sealed class NavigationLifecycleHelper
    {

        #region Variables

        private readonly Page _page;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="page">The page to monitor.</param>
        public NavigationLifecycleHelper(Page page)
        {
            _page = page;
        }

        #endregion

        #region Public API

        /// <summary>
        /// Handles a disappear event
        /// </summary>
        /// <returns><c>true</c>, if the page disappeared and was processed, <c>false</c> otherwise.</returns>
        /// <param name="navigation">The navigation item in question when the disappear happened.</param>
        public bool OnDisappearing(INavigation navigation)
        {
            if(navigation.NavigationStack.Last() == _page) {
                (_page.BindingContext as IDisposable)?.Dispose();
                return true;
            }

            return false;
        }

        #endregion

    }
}


