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

namespace Training.Core
{
    /// <summary>
    /// The model for an entry in the TaskListsPage table view
    /// </summary>
    public class TaskListModel : BaseModel
    {
        private Document _document;

        public string Name
        {
            get {
                return _document.GetProperty<string>("name");
            }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="databaseName">The name of the database to use.</param>
        /// <param name="documentId">The ID of the document containing information for this entry</param>
        public TaskListModel(string databaseName, string documentId)
        {
            var db = CoreApp.AppWideManager.GetDatabase(databaseName);
            _document = db.GetExistingDocument(documentId);
        }

        /// <summary>
        /// Deletes the list entry
        /// </summary>
        public void Delete()
        {
            try {
                _document.Delete();
            } catch(Exception e) {
                throw new ApplicationException("Couldn't delete task list", e);
            }
        }

        /// <summary>
        /// Edits the list entry's name
        /// </summary>
        /// <param name="name">The new name to use.</param>
        public void Edit(string name)
        {
            try {
                _document.Update(rev =>
                {
                    var props = rev.UserProperties;
                    var lastName = props["name"];
                    props["name"] = name;
                    rev.SetUserProperties(props);

                    return !String.Equals(name, lastName);
                });
            } catch(Exception e) {
                throw new ApplicationException("Couldn't edit task list", e);
            }
        }
    }
}

