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
using Couchbase.Lite.Query;

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

        private IDatabase _db;
        //private LiveQuery _byNameQuery;
        //private LiveQuery _incompleteQuery;

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
        public string Username => _db?.Name;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="db">The database to use</param>
        public TaskListsModel(IDatabase db)
        {
            _db = db;
            SetupQuery();
        }

        #endregion

        #region Public API

        //public void TestConflict()
        //{
        //    var savedRevision = CreateTaskList("Test Conflicts List");
        //    var newRev1 = savedRevision.CreateRevision();
        //    var propsRev1 = newRev1.Properties;
        //    propsRev1["name"] = "Foosball";
        //    newRev1.SetProperties(propsRev1);
        //    var newRev2 = savedRevision.CreateRevision();
        //    var propsRev2 = newRev2.Properties;
        //    propsRev2["name"] = "Table Football";
        //    newRev2.SetProperties(propsRev2);
        //    try {
        //        newRev1.Save(true);
        //        newRev2.Save(true);
        //    } catch(Exception e) {
        //        throw new Exception("Could not create document", e);
        //    }
        //}

        /// <summary>
        /// Creates a new task list
        /// </summary>
        /// <param name="name">The name of the task list.</param>
        public IDocument CreateTaskList(string name)
        {
            var docId = $"{Username}.{Guid.NewGuid()}";
            try {
                var returnVal = _db.DoSync(() =>
                {
                    var doc = _db.GetDocument(docId);
                    doc["type"] = TaskListType;
                    doc["name"] = name;
                    doc["owner"] = Username;
                    doc.Save();
                    return doc;
                });
                Filter(null);
                return returnVal;
            } catch(Exception e) {
                var newException = new Exception("Couldn't save task list", e);
                throw newException;
            }
        }

        public void Filter(string searchText)
        {
            var query = default(IQuery);
            if(!String.IsNullOrEmpty(searchText)) {
                query = QueryFactory.Select("name")
                    .From(DataSourceFactory.Database(_db))
                    .Where(ExpressionFactory.Property("name")
                        .Like($"%{searchText}%")
                        .And(ExpressionFactory.Property("type").EqualTo("task-list")))
                    .OrderBy(OrderByFactory.Property("name"));
            } else {
                query = QueryFactory.Select("name")
                    .From(DataSourceFactory.Database(_db))
                    .Where(ExpressionFactory.Property("name")
                        .NotNull()
                        .And(ExpressionFactory.Property("type").EqualTo("task-list")))
                    .OrderBy(OrderByFactory.Property("name"));
            }

            TasksList.Replace(query.Run().Select(x => new TaskListCellModel(x.DocumentID, x.Document["name"] as string)));
        }

        #endregion

        #region Private API

        private void SetupQuery()
        {
            _db.CreateIndex(new[] { ExpressionFactory.Property("name") });
            Filter(null);
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            _db.Close();
        }

        #endregion

    }
}

