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

        private LiveQuery _tasksLiveQuery;
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
        public string DatabaseName
        {
            get {
                return _db.Name;
            }
        }

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
            SetupViewAndQuery();
        }

        #endregion

        #region Public API

        public void TestConfict()
        {
            // TRAINING: Create task conflict (for development only)
            var savedRevision = CreateNewTask("Text");
            var newRev1 = savedRevision.CreateRevision();
            var propsRev1 = newRev1.Properties;
            propsRev1["task"] = "Text Changed";
            var newRev2 = savedRevision.CreateRevision();
            var propsRev2 = newRev2.Properties;
            propsRev2["complete"] = true;
            newRev1.Save(true);
            newRev2.Save(true);
        }

        /// <summary>
        /// Creates a new task in the current list
        /// </summary>
        /// <param name="taskName">The name of the task</param>
        public SavedRevision CreateNewTask(string taskName)
        {
            var taskListInfo = new Dictionary<string, object> {
                ["id"] = _taskList.Id,
                ["owner"] = _taskList.GetProperty<string>("owner")
            };

            var properties = new Dictionary<string, object> {
                ["type"] = TaskType,
                ["taskList"] = taskListInfo,
                ["createdAt"] = DateTime.UtcNow,
                ["task"] = taskName,
                ["complete"] = false
            };

            try {
                return _db.CreateDocument().PutProperties(properties);
            } catch(Exception e) {
                throw new ApplicationException("Couldn't save task", e);
            }
        }

        /// <summary>
        /// Filters the list of tasks based on a given search string.
        /// </summary>
        /// <param name="searchString">The search string to filter on.</param>
        public void Filter(string searchString)
        {
            if(!String.IsNullOrEmpty(searchString)) {
                _tasksLiveQuery.PostFilter = row => {
                    var key = JsonUtility.ConvertToNetList<object>(row.Key);
                    var name = key[2] as string;
                    if(name == null) {
                        return false;
                    }

                    return name.ToLower().Contains(searchString.ToLower());
                };
            } else {
                _tasksLiveQuery.PostFilter = null;
            }

            _tasksLiveQuery.QueryOptionsChanged();
        }

        #endregion

        #region Private API

        private void SetupViewAndQuery()
        {
            var view = _db.GetView("tasksByCreatedAt");
            view.SetMap((doc, emit) =>
            {
                if(!doc.ContainsKey("type")) {
                    return;
                }

                var type = doc["type"] as string;
                if(type != "task") {
                    return;
                }


                var elements = new List<object>();
                if(!doc.Extract(elements, "taskList", "createdAt", "task")) {
                    return;
                }

                var listInfo = JsonUtility.ConvertToNetObject<IDictionary<string, object>>(elements[0]);
                if(!listInfo.ContainsKey("id")) {
                    return;
                }

                elements[0] = listInfo["id"];

                emit(elements.ToArray(), null);
            }, "1.0");

            _tasksLiveQuery = view.CreateQuery().ToLiveQuery();
            _tasksLiveQuery.StartKey = new[] { _taskList.Id };
            _tasksLiveQuery.EndKey = new[] { _taskList.Id };
            _tasksLiveQuery.PrefixMatchLevel = 1;
            _tasksLiveQuery.Descending = false;
            _tasksLiveQuery.Changed += (sender, e) =>
            {
                ListData.Replace(e.Rows.Select(x => new TaskCellModel(x.DocumentId)));
            };
            _tasksLiveQuery.Start();
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            _tasksLiveQuery.Stop();
            ListData.Clear();
        }

        #endregion

    }
}

