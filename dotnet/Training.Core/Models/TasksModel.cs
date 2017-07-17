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

        private const string TaskType = "task";

        #endregion

        #region Variables

        //private LiveQuery _tasksLiveQuery;
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
                ["createdAt"] = DateTime.UtcNow,
                ["task"] = taskName,
                ["complete"] = false
            };

            try {
                var doc = new Document(properties);
                _db.Save(doc);
                Filter(null);
                return doc;
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
                query = QueryFactory.Select()
                    .From(DataSourceFactory.Database(_db))
                    .Where(ExpressionFactory.Property("type").EqualTo(TaskType)
                    .And(ExpressionFactory.Property("taskList").EqualTo(_taskList.Id))
                    .And(ExpressionFactory.Property("task").Like($"%{searchString}%")))
                    .OrderBy(OrderByFactory.Property("createdAt"));
            } else {
                query = QueryFactory.Select()
                    .From(DataSourceFactory.Database(_db))
                    .Where(ExpressionFactory.Property("type").EqualTo(TaskType));
                //.And(ExpressionFactory.Property("taskList").EqualTo(_taskList.Id)))
                //.OrderBy(OrderByFactory.Property("createdAt"));
            }

            ListData.Replace(query.Run().Select(x => new TaskCellModel(x.DocumentID)));
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            ListData.Clear();
        }

        #endregion

    }
}

