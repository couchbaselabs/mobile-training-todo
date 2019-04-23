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
using Couchbase.Lite.Query;
using Training.Core;
using Training.ViewModels;

namespace Training.Models
{
    /// <summary>
    /// The model for UsersViewModel
    /// </summary>
    public class UsersModel
    {

        #region Constants

        private const string UserType = "task-list.user";

        #endregion

        #region Variables

        private Database _db;
        private IQuery _filteredQuery;
        private IQuery _fullQuery;
        private IQuery _usersLiveQuery;
        private Document _userList;
        private string _searchUserName;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the applicable list of users
        /// </summary>
        public ObservableCollection<UserCellModel> UserList { get; } =
            new ObservableCollection<UserCellModel>();

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="currentListId">The document ID of the list to check for users</param>
        public UsersModel(string currentListId)
        {
            _db = CoreApp.Database;
            _userList = _db.GetDocument(currentListId);
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
                ["id"] = _userList.Id,
                ["owner"] = _userList.GetString("owner")
            };

            var properties = new Dictionary<string, object> {
                ["type"] = UserType,
                ["taskList"] = taskListInfo,
                ["username"] = username
            };

            var docId = $"{_userList.Id}.{username}";
            try {
                var doc = new MutableDocument(docId, properties);
                _db.Save(doc);
                Filter(_searchUserName);
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
            _searchUserName = searchString;
            var query = default(IQuery);
            if (!String.IsNullOrEmpty(searchString)) {
                query = _filteredQuery;
                query.Parameters.SetString("searchText", $"%{searchString}%");
            } else {
                query = _fullQuery;
            }

            var results = query.Execute();
            //UserList.Replace(results.Select(x =>
            //{
            //    var docId = $"{_userList.Id}.{x.GetString(0)}";
            //    return new UserCellModel(docId);
            //}));
        }

        #endregion

        #region Private API

        private void SetupQuery()
        {
            var username = Expression.Property("username");
            var exp1 = Expression.Property("type").EqualTo(Expression.String(UserType));
            var exp2 = Expression.Property("taskList.id").EqualTo(Expression.String(_userList.Id));

            _filteredQuery = QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Database(_db))
                .Where(username
                    .Like(Expression.Parameter("searchText"))
                    .And((exp1).And(exp2)))
                .OrderBy(Ordering.Property("username"));

            _fullQuery = QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Database(_db))
                .Where(username
                    .NotNullOrMissing()
                    .And((exp1).And(exp2)))
                .OrderBy(Ordering.Property("username"));

            _usersLiveQuery = QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Database(_db))
                .Where((exp1).And(exp2)).OrderBy(Ordering.Property("username"));

            var results = _usersLiveQuery.Execute();

            //_usersLiveQuery.AddChangeListener((sender, args) =>
            //{
            //    UserList.Replace(results.Select(x =>
            //    {
            //        var docId = $"{_userList.Id}.{x.GetString(0)}";
            //        return new UserCellModel(docId);
            //    }));
            //});
        }

        #endregion

    }
}

