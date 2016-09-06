//
// UsersModel.cs
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
using System.Linq;
using Couchbase.Lite;

namespace Training.Core
{
    public class UsersModel : BaseModel, IDisposable
    {
        private const string UserType = "task-list.user";

        private Database _db;
        private LiveQuery _usersLiveQuery;
        private Document _taskList;

        public ExtendedObservableCollection<UserCellModel> ListData { get; } = new ExtendedObservableCollection<UserCellModel>();

        public UsersModel(string databaseName, string currentListId)
        {
            _db = CoreApp.AppWideManager.GetDatabase(databaseName);
            _taskList = _db.GetDocument(currentListId);
            SetupViewAndQuery();
        }

        public void CreateNewUser(string username)
        {
            var taskListInfo = new Dictionary<string, object> {
                ["id"] = _taskList.Id,
                ["owner"] = _taskList.GetProperty<string>("owner")
            };

            var properties = new Dictionary<string, object> {
                ["type"] = UserType,
                ["taskList"] = taskListInfo,
                ["username"] = username
            };

            var docId = $"{_taskList.Id}.{username}";
            try {
                _db.GetDocument(docId).PutProperties(properties);
            } catch(Exception e) {
                throw new ApplicationException("Couldn't create user", e);
            }
        }

        public void Filter(string searchString)
        {
            if(!String.IsNullOrEmpty(searchString)) {
                _usersLiveQuery.StartKey = new[] { _taskList.Id, searchString };
                _usersLiveQuery.PrefixMatchLevel = 2;
            } else {
                _usersLiveQuery.StartKey = new[] { _taskList.Id };
                _usersLiveQuery.PrefixMatchLevel = 1;
            }

            _usersLiveQuery.EndKey = _usersLiveQuery.StartKey;
            _usersLiveQuery.QueryOptionsChanged();
        }

        private void SetupViewAndQuery()
        {
            var view = _db.GetView("usersByUsername");
            view.SetMap((doc, emit) =>
            {
                var elements = new List<object>();
                if(!doc.Extract(elements, "type", "username", "taskList")) {
                    return;
                }

                if(elements[0] as string != UserType) {
                    return;
                }

                var listInfo = JsonUtility.ConvertToNetObject<IDictionary<string, object>>(elements[2]);
                var listId = listInfo?["id"] as string;
                emit(new[] { listId, elements[1] }, null);
            }, "1.0");

            _usersLiveQuery = view.CreateQuery().ToLiveQuery();
            _usersLiveQuery.StartKey = new[] { _taskList.Id };
            _usersLiveQuery.EndKey = new[] { _taskList.Id };
            _usersLiveQuery.PrefixMatchLevel = 1;
            _usersLiveQuery.Changed += (sender, e) => 
            {
                ListData.Replace(e.Rows.Select(x =>
                {
                    var key = JsonUtility.ConvertToNetList<string>(x.Key);
                    var id = key[0];
                    var name = key[1];
                    var docId = $"{id}.{name}";
                    return new UserCellModel(_db.Name, docId);
                }));
            };
            _usersLiveQuery.Start();
        }

        public void Dispose()
        {
            _usersLiveQuery.Stop();
        }
    }
}

