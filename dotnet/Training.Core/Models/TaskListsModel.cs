//
// TaskListsModel.cs
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
using System.Linq;

using Couchbase.Lite;
using Couchbase.Lite.Views;

namespace Training.Core
{
    /// <summary>
    /// The model for the list of task lists page
    /// </summary>
    public sealed class TaskListsModel : BaseModel, IDisposable
    {

        #region Constants

        private const string TaskListType = "task-list";

        #endregion

        #region Variables

        private Database _db;
        private LiveQuery _byNameQuery;
        private LiveQuery _incompleteQuery;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the list of task lists currently saved
        /// </summary>
        public ExtendedObservableCollection<TaskListCellModel> TasksList { get; } = 
            new ExtendedObservableCollection<TaskListCellModel>();

        /// <summary>
        /// Gets the username of the user using the app
        /// </summary>
        public string Username
        {
            get {
                return _db?.Name;
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="db">The database to use</param>
        public TaskListsModel(Database db)
        {
            _db = db;
            SetupViewAndQuery();
        }

        #endregion

        #region Public API

        public void TestConflict()
        {
            var savedRevision = CreateTaskList("Test Conflicts List");
            var newRev1 = savedRevision.CreateRevision();
            var propsRev1 = newRev1.Properties;
            propsRev1["name"] = "Foosball";
            newRev1.SetProperties(propsRev1);
            var newRev2 = savedRevision.CreateRevision();
            var propsRev2 = newRev2.Properties;
            propsRev2["name"] = "Table Football";
            newRev2.SetProperties(propsRev2);
            try {
                newRev1.Save(true);
                newRev2.Save(true);
            } catch(Exception e) {
                throw new ApplicationException("Could not create document", e);
            }
        }

        /// <summary>
        /// Creates a new task list
        /// </summary>
        /// <param name="name">The name of the task list.</param>
        public SavedRevision CreateTaskList(string name)
        {
            var properties = new Dictionary<string, object> {
                ["type"] = TaskListType,
                ["name"] = name,
                ["owner"] = Username
            };

            var docId = $"{Username}.{Guid.NewGuid()}";
            var doc = default(Document);
            try {
                doc = _db.GetDocument(docId);
                return doc.PutProperties(properties);
            } catch(Exception e) {
                var newException = new ApplicationException("Couldn't save task list", e);
                throw newException;
            }
        }

        public void Filter(string searchText)
        {
            if(!String.IsNullOrEmpty(searchText)) {
                _byNameQuery.StartKey = searchText;
                _byNameQuery.PrefixMatchLevel = 1;
            } else {
                _byNameQuery.StartKey = null;
                _byNameQuery.PrefixMatchLevel = 0;
            }

            _byNameQuery.EndKey = _byNameQuery.StartKey;
            _byNameQuery.QueryOptionsChanged();
        }

        #endregion

        #region Private API

        private void SetupViewAndQuery()
        {
            var view = _db.GetView("list/listsByName");
            view.SetMap((doc, emit) =>
            {
                if(!doc.ContainsKey("type") || doc["type"] as string != "task-list" || !doc.ContainsKey("name")) {
                    return;
                }

                emit(doc["name"], null);
            }, "1.0");

            _byNameQuery = view.CreateQuery().ToLiveQuery();
            _byNameQuery.Changed += (sender, args) =>
            {
                TasksList.Replace(args.Rows.Select(x => new TaskListCellModel(x.DocumentId, x.Key as string)));
            };
            _byNameQuery.Start();

            var incompleteTasksView = _db.GetView("list/incompleteTasksCount");
            incompleteTasksView.SetMapReduce((doc, emit) =>
            {
                if(!doc.ContainsKey("type") || doc["type"] as string != "task") {
                    return;
                }

                if(!doc.ContainsKey("taskList")) {
                    return;
                }

                var list = JsonUtility.ConvertToNetObject<IDictionary<string, object>>(doc["taskList"]);
                if(!list.ContainsKey("id") || (doc.ContainsKey("complete") && (bool)doc["complete"])) {
                    return;
                }

                emit(list["id"], null);

             }, BuiltinReduceFunctions.Count, "1.0");

            _incompleteQuery = incompleteTasksView.CreateQuery().ToLiveQuery();
            _incompleteQuery.GroupLevel = 1;
            _incompleteQuery.Changed += (sender, e) => 
            {
                var newItems = TasksList.ToList();
                foreach(var row in e.Rows) {
                    var item = newItems.FirstOrDefault(x => x.DocumentID == row.Key as string);
                    if(item != null) {
                        item.IncompleteCount = (int)row.Value;
                    }
                }

                TasksList.Replace(newItems);
            };
            _incompleteQuery.Start();
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            _byNameQuery.Stop();
            _incompleteQuery.Stop();
            _db.Close();
        }

        #endregion

    }
}

