//
// TaskListModel.cs
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
using Robo.Mvvm;
using Training.Core;

namespace Training.Models
{
    /// <summary>
    /// The model for an entry in the TaskListsPage table view
    /// </summary>
    public class TaskListModel : BaseNotify
    {

        #region Variables

        private Document _document;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the name of the list
        /// </summary>
        public string Name => _document?.GetString("name");

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentId">The ID of the document containing information for this entry</param>
        public TaskListModel(string documentId)
        {
            _document = CoreApp.Database.GetDocument(documentId);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Deletes the list entry
        /// </summary>
        public bool Delete()
        {
            if(_document == null) {
                return true;
            }

            var db = CoreApp.Database;
            if (_document.GetString("owner") != db.Name && !HasModerator(db))
            {
                return false;
            }

            try {
                db.Delete(_document);
                _document = null;
            }
            catch (Exception e)
            {
                throw new Exception("Couldn't delete task list", e);
            }

            return true;
        }

        /// <summary>
        /// Edits the list entry's name
        /// </summary>
        /// <param name="name">The new name to use.</param>
        public string Edit(string name)
        {
            try {
                using(var mutableDoc = _document.ToMutable()) {
                    mutableDoc.SetString("name", name);
                    var document = _document;
                    CoreApp.Database.Save(mutableDoc);
                    _document = mutableDoc;
                    document.Dispose();
                    return name;
                }
            } catch(Exception e) {
                throw new Exception("Couldn't edit task list", e);
            }
        }

        #endregion

        #region Private API

        private bool HasModerator(Database db)
        {
            var moderatorDocId = $"moderator.{db.Name}";
            var doc = db.GetDocument(moderatorDocId);
            doc?.Dispose();
            return doc != null;
        }

        #endregion
    }
}

