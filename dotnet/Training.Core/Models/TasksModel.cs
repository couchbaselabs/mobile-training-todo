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
using System.Collections.ObjectModel;

using Couchbase.Lite;

namespace Training.Core
{
    /// <summary>
    /// The model for the list of tasks page
    /// </summary>
    public sealed class TasksModel : BaseModel, IDisposable
    {
        private const string TaskType = "task";

        private LiveQuery _tasksLiveQuery;
        private Database _db;
        private Document _taskList;

        /// <summary>
        /// Gets the list of tasks for the current list
        /// </summary>
        public ObservableCollection<TaskCellModel> ListData { get; } = new ObservableCollection<TaskCellModel>();

        /// <summary>
        /// Gets the name of the database being worked on
        /// </summary>
        public string DatabaseName
        {
            get {
                return _db.Name;
            }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="dbName">The name of the database to operate on</param>
        /// <param name="listId">The id of the list to retrieve tasks from</param>
        public TasksModel(string dbName, string listId)
        {
            _db = CoreApp.AppWideManager.GetDatabase(dbName);
            _taskList = _db.GetDocument(listId);
            SetupViewAndQuery();
        }

        /// <summary>
        /// Creates a new task in the current list
        /// </summary>
        /// <param name="taskName">The name of the task</param>
        public void CreateNewTask(string taskName)
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
                _db.CreateDocument().PutProperties(properties);
            } catch(Exception e) {
                throw new ApplicationException("Couldn't save task", e);
            }
        }

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
            //_tasksLiveQuery.StartKey = _taskList.Id;
            //_tasksLiveQuery.EndKey = _taskList.Id;
            _tasksLiveQuery.PrefixMatchLevel = 1;
            _tasksLiveQuery.Descending = true;
            _tasksLiveQuery.Changed += (sender, e) =>
            {
                if(ListData.Count != e.Rows.Count) { 
                    ListData.Clear();
                    foreach(var row in e.Rows) {
                        var doc = row.Document;
                        var rev = doc.CurrentRevision;
                        ListData.Add(new TaskCellModel(doc));
                    }
                }
            };
            _tasksLiveQuery.Start();
        }

        public void Dispose()
        {
            _tasksLiveQuery.Stop();
        }
    }
}

