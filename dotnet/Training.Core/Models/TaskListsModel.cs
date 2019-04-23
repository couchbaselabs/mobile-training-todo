// 
// TaskListsModel.cs
// 
// Author:
//     Jim Borden  <jim.borden@couchbase.com>
// 
// Copyright (c) 2017 Couchbase, Inc All rights reserved.
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
using Couchbase.Lite.Util;
using Training.Core;
using Training.ViewModels;

namespace Training.Models
{
    /// <summary>
    /// The model for the list of task lists page
    /// </summary>
    public sealed class TaskListsModel : IDisposable
    {
        #region Constants

        private const string TaskListType = "task-list";

        #endregion

        #region Variables

        private Database _db;
        private IQuery _filteredQuery;
        private IQuery _fullQuery;
        private IQuery _incompleteQuery;
        private string _searchText;
        private readonly IDictionary<string, int> _incompleteCount = new Dictionary<string, int>();

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
        public TaskListsModel()
        {
            _db = CoreApp.Database;
            SetupQuery();
            Filter(null);
        }

        #endregion

        #region Public Methods

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
        public Document CreateTaskList(string name)
        {
            var docId = $"{Username}.{Guid.NewGuid()}";
            try {
                var doc = new MutableDocument(docId);
                doc["type"].Value = TaskListType;
                doc["name"].Value = name;
                doc["owner"].Value = Username;
                _db.Save(doc);
                Filter(_searchText);
                return doc;
            } catch(Exception e) {
                var newException = new Exception("Couldn't save task list", e);
                throw newException;
            }
        }

        public void Filter(string searchText)
        {
            _searchText = searchText;
            var query = default(IQuery);
            if(!String.IsNullOrEmpty(searchText)) {
                query = _filteredQuery;
                query.Parameters.SetString("searchText", $"%{searchText}%");
            } else {
                query = _fullQuery;
            }

            var results = query.Execute();
            //TasksList.Replace(results.Select(x => new TaskListCellModel(x.GetString(0), x.GetString(1))
            //{
            //    IncompleteCount = _incompleteCount.ContainsKey(x.GetString(0)) ? _incompleteCount[x.GetString(0)] : 0
            //}));
        }

        #endregion

        #region Private Methods

        private void SetupQuery()
        {
            _db.CreateIndex("byName", IndexBuilder.ValueIndex(ValueIndexItem.Expression(Expression.Property("name"))));

            _filteredQuery = QueryBuilder.Select(SelectResult.Expression(Meta.ID), 
                SelectResult.Expression(Expression.Property("name")))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("name")
                    .Like(Expression.Parameter("searchText"))
                    .And(Expression.Property("type").EqualTo(Expression.String("task-list"))))
                .OrderBy(Ordering.Property("name"));

            _fullQuery = QueryBuilder.Select(SelectResult.Expression(Meta.ID),
                    SelectResult.Expression(Expression.Property("name")))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("name")
                    .NotNullOrMissing()
                    .And(Expression.Property("type").EqualTo(Expression.String("task-list"))))
                .OrderBy(Ordering.Property("name"));

            _incompleteQuery = QueryBuilder.Select(SelectResult.Expression(Expression.Property("taskList.id")),
                    SelectResult.Expression(Function.Count(Expression.All())))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String(TasksModel.TaskType))
                       .And(Expression.Property("complete").EqualTo(Expression.Boolean(false))))
                .GroupBy(Expression.Property("taskList.id"));

            _incompleteQuery.AddChangeListener((sender, args) =>
            {
                _incompleteCount.Clear();
                foreach (var result in args.Results)
                {
                    _incompleteCount[result.GetString(0)] = result.GetInt(1);
                }

                foreach (var row in TasksList) {
                    row.IncompleteCount = _incompleteCount.ContainsKey(row.DocumentID)
                        ? _incompleteCount[row.DocumentID]
                        : 0;
                }
            });
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            _db.Close();
            _incompleteQuery.Dispose();
            _fullQuery.Dispose();
            _filteredQuery.Dispose();
        }

        #endregion
    }
}

