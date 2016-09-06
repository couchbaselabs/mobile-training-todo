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
using System.Collections.Generic;
using Couchbase.Lite;

namespace Training.Core
{
    public sealed class ListDetailModel : BaseModel, IDisposable
    {
        private Database _db;
        private Document _document;
        private string _username;

        public event EventHandler ModeratorStatusGained;

        public string Owner
        {
            get {
                return _document.GetProperty<string>("owner");
            }
        }

        public ListDetailModel(string dbName, string documentId)
        {
            _db = CoreApp.AppWideManager.GetDatabase(dbName);
            _document = _db.GetExistingDocument(documentId);
            _db.Changed += MonitorModeratorStatus;
        }

        public bool HasModerator(string username)
        {
            var moderatorDocId = $"moderator.{username}";
            return _db.GetExistingDocument(moderatorDocId) != null;
        }

        public void TrackModeratorStatus(string username)
        {
            _username = username;
        }

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

        public void Dispose()
        {
            if(_username == null) {
                return;
            }

            _db.Changed -= MonitorModeratorStatus;
        }
    }
}

