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
using System.Linq;

using Couchbase.Lite;
using Couchbase.Lite.Query;

namespace Training.Core
{
    /// <summary>
    /// The model for UsersViewModel
    /// </summary>
    public class UsersModel : BaseModel
    {

        #region Constants

        private const string UserType = "task-list.user";

        #endregion

        #region Variables

        private Database _db;
        private IQuery _usersLiveQuery;
        private Document _taskList;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the applicable list of users
        /// </summary>
        public ExtendedObservableCollection<UserCellModel> ListData { get; } = new ExtendedObservableCollection<UserCellModel>();

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="currentListId">The document ID of the list to check for users</param>
        public UsersModel(string currentListId)
        {
            _db = CoreApp.Database;
            _taskList = _db.GetDocument(currentListId);
            SetupQuery();
        }

        #endregion

        #region Public API

        /// <summary>
        /// Creates a new user for the associated list
        /// </summary>
        /// <param name="username">The username to create.</param>
        public void CreateNewUser(string username)
        {
            var taskListInfo = new Dictionary<string, object> {
                ["id"] = _taskList.Id,
                ["owner"] = _taskList.GetString("owner")
            };

            var properties = new Dictionary<string, object> {
                ["type"] = UserType,
                ["taskList"] = taskListInfo,
                ["username"] = username
            };

            var docId = $"{_taskList.Id}.{username}";
            try {
                var doc = new MutableDocument(docId, properties);
                _db.Save(doc);
            } catch(Exception e) {
                throw new Exception("Couldn't create user", e);
            }
        }

        /// <summary>
        /// Filters the users list based on a given string
        /// </summary>
        /// <param name="searchString">The string to filter on.</param>
        public void Filter(string searchString)
        {
           
        }

        #endregion

        #region Private API

        private void SetupQuery()
        {
            var username = Expression.Property("username");
            _usersLiveQuery = QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String(UserType)).And(Expression.Property("taskList.id").EqualTo(Expression.String(_taskList.Id))))
                                   .OrderBy(Ordering.Property("username"));

            _usersLiveQuery.AddChangeListener((sender, args) =>
            {
                ListData.Replace(args.Results.Select(x =>
                {
                    var docId = $"{_taskList.Id}.{x.GetString(0)}";
                    return new UserCellModel(docId);
                }));
            });
        }

        #endregion

    }
}

