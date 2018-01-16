//
// TasksModel.cs
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
    /// The model for the list of tasks page
    /// </summary>
    public sealed class TasksModel : BaseModel, IDisposable
    {

        #region Constants

        internal const string TaskType = "task";

        #endregion

        #region Variables

        private IQuery _tasksFilteredQuery;
        private IQuery _tasksFullQuery;
        private Database _db;
        private Document _taskList;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the list of tasks for the current list
        /// </summary>
        public ExtendedObservableCollection<TaskCellModel> ListData { get; } = 
            new ExtendedObservableCollection<TaskCellModel>();

        /// <summary>
        /// Gets the name of the database being worked on
        /// </summary>
        public string DatabaseName => _db.Name;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="listId">The id of the list to retrieve tasks from</param>
        public TasksModel(string listId)
        {
            _db = CoreApp.Database;
            _taskList = _db.GetDocument(listId);
            SetupQuery();
            Filter(null);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Creates a new task in the current list
        /// </summary>
        /// <param name="taskName">The name of the task</param>
        public Document CreateNewTask(string taskName)
        {
            var taskListInfo = new Dictionary<string, object> {
                ["id"] = _taskList.Id,
                ["owner"] = _taskList.GetString("owner")
            };

            var properties = new Dictionary<string, object> {
                ["type"] = TaskType,
                ["taskList"] = taskListInfo,
                ["createdAt"] = DateTimeOffset.UtcNow,
                ["task"] = taskName,
                ["complete"] = false
            };

            try {
                using (var doc = new MutableDocument(properties))
                {
                    var retVal = _db.Save(doc);
                    Filter(null);
                    return retVal;
                }
            } catch(Exception e) {
                throw new Exception("Couldn't save task", e);
            }
        }

        /// <summary>
        /// Filters the list of tasks based on a given search string.
        /// </summary>
        /// <param name="searchString">The search string to filter on.</param>
        public void Filter(string searchString)
        {
            var query = default(IQuery);
            if(!String.IsNullOrEmpty(searchString)) {
                query = _tasksFilteredQuery;
                query.Parameters.SetString("searchString", $"%{searchString}%");
            } else {
                query = _tasksFullQuery;
            }

            using (var results = query.Execute()) {
                ListData.Replace(results.Select(x => new TaskCellModel(x.GetString(0))));
            }
        }

        private void SetupQuery()
        {
            _tasksFilteredQuery = Query.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(TaskType)
                    .And(Expression.Property("taskList.id").EqualTo(_taskList.Id))
                    .And(Expression.Property("task").Like(Expression.Parameter("searchString"))))
                .OrderBy(Ordering.Property("createdAt"));

            _tasksFullQuery = Query.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(TaskType)
                    .And(Expression.Property("taskList.id").EqualTo(_taskList.Id)))
                .OrderBy(Ordering.Property("createdAt"));
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            ListData.Clear();
            _tasksFilteredQuery.Dispose();
            _tasksFullQuery.Dispose();
        }

        #endregion

    }
}

