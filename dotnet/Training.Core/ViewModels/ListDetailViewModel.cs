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
using System;

namespace Training.Core
{
    /// <summary>
    /// The view model for the task list / users tabbed view of the application
    /// </summary>
    public class ListDetailViewModel : BaseViewModel<ListDetailModel>, IDisposable
    {

        #region Properties

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
                SetProperty(ref _hasModeratorStatus, value);
            }
        }
        private bool _hasModeratorStatus;

        /// <summary>
        /// Gets the title of the page
        /// </summary>
        /// <value>The page title.</value>
        public string PageTitle
        {
            get; private set;
        }

        internal string CurrentListID
        {
            get; private set;
        }

        internal string Username
        {
            get; private set;
        }

        #endregion

        #region Public API

        /// <summary>
        /// Initializes the view model with data passed to it
        /// </summary>
        /// <param name="username">The username of the current user.</param>
        /// <param name="name">The name of the task.</param>
        /// <param name="listID">The task document ID.</param>
        public void Init(string username, string name, string listID)
        {
            Username = username;
            PageTitle = name;
            CurrentListID = listID;
            Model = new ListDetailModel(listID);
            CalculateModeratorStatus();
        }

        #endregion

        #region Private API

        private void CalculateModeratorStatus()
        {
            var owner = Model.Owner;
            if(Username.Equals(owner) || Model.HasModerator(Username)) {
                HasModeratorStatus = true;
                return;
            }

            Model.TrackModeratorStatus(Username);
            Model.ModeratorStatusGained += (sender, e) => HasModeratorStatus = true;
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

