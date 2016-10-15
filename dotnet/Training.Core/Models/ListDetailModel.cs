//
// ListDetailModel.cs
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

using Couchbase.Lite;

namespace Training.Core
{
    /// <summary>
    /// The model for the list detail page (tabbed page containing tasks list
    /// and users list as children)
    /// </summary>
    public sealed class ListDetailModel : BaseModel, IDisposable
    {

        #region Variables

        private Database _db;
        private Document _document;
        private string _username;

        /// <summary>
        /// Fired when a change in the database causes moderator status to be
        /// gained (enabling the users page to be visible)
        /// </summary>
        public event EventHandler ModeratorStatusGained;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the owner of the list being shown
        /// </summary>
        public string Owner
        {
            get {
                return _document.GetProperty<string>("owner");
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentId">The ID of the document containing the list details</param>
        public ListDetailModel(string documentId)
        {
            _db = CoreApp.Database;
            _document = _db.GetExistingDocument(documentId);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Calculates whether or not the given user has moderator access to the 
        /// current list
        /// </summary>
        /// <returns><c>true</c>, if the user has access, <c>false</c> otherwise.</returns>
        /// <param name="username">The user to check access for.</param>
        public bool HasModerator(string username)
        {
            var moderatorDocId = $"moderator.{username}";
            return _db.GetExistingDocument(moderatorDocId) != null;
        }

        /// <summary>
        /// Triggers the class to monitor the database until a change occurs
        /// that enabled moderator access for the given user
        /// </summary>
        /// <param name="username">The username to track.</param>
        public void TrackModeratorStatus(string username)
        {
            if(_username == null && username == null) {
                return;
            }

            if(_username == null) {
                _db.Changed += MonitorModeratorStatus;
            } else if(username == null) {
                _db.Changed -= MonitorModeratorStatus;
            }

            _username = username;

        }

        #endregion

        #region Private API

        private void MonitorModeratorStatus(object sender, DatabaseChangeEventArgs e)
        {
            if(_username == null) {
                return;
            }

            foreach(var change in e.Changes) {
                if(change.SourceUrl == null) {
                    continue;
                }

                var moderatorDocId = $"moderator.{_username}";
                if(change.DocumentId == moderatorDocId) {
                    ModeratorStatusGained?.Invoke(this, null);
                    _username = null;
                    _db.Changed -= MonitorModeratorStatus;
                }
            }
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            if(_username == null) {
                return;
            }

            _db.Changed -= MonitorModeratorStatus;
        }

        #endregion
    }
}

