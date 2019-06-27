//
// UsersViewModel.cs
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
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;
using Couchbase.Lite;
using Couchbase.Lite.Query;
using Robo.Mvvm.Input;
using Robo.Mvvm.Services;
using Training.Core;
using Training.Models;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for the users page
    /// </summary>
    public class UsersViewModel : BaseNavigationViewModel
    {
        #region Constants

        private const string UserType = "task-list.user";

        #endregion

        #region Variables

        private IUserDialogs _dialogs;

        private Database _db = CoreApp.Database;
        private IQuery _filteredQuery;
        private IQuery _fullQuery;
        private IQuery _usersLiveQuery;
        private Document _userList;
        private string _searchUserName;

        #endregion

        #region Properties

        /// <summary>
        /// Gets or sets the current text being searched for in the list
        /// </summary>
        public string SearchTerm
        {
            get {
                return _searchTerm;
            }
            set {
                if(SetPropertyChanged(ref _searchTerm, value)) {
                    Filter(value);
                }
            }
        }
        private string _searchTerm;

        public UserCellModel SelectedItem
        {
            get {
                return _selectedItem;
            }
            set {
                _selectedItem = value;
                SetPropertyChanged(ref _selectedItem, null); // No "selection" effect
            }
        }
        private UserCellModel _selectedItem;

        /// <summary>
        /// Gets the handler for an add request
        /// </summary>
        public ICommand AddCommand => new Command(async () => await AddNewUser());

        ICommand _selectCommand;
        public ICommand SelectCommand
        {
            get
            {
                if (_selectCommand == null)
                {
                    _selectCommand = new Command<KeyValuePair<string, UserCellModel>>((pair) => SelectList(pair));
                }

                return _selectCommand;
            }
        }

        /// <summary>
        /// Gets the current list of users for the list
        /// </summary>
        /// <value>The list data.</value>
        ObservableConcurrentDictionary<string, UserCellModel> _items = new ObservableConcurrentDictionary<string, UserCellModel>();
        public ObservableConcurrentDictionary<string, UserCellModel> ListData
        {
            get { return _items; }
            set
            {
                _items = value;
                SetPropertyChanged(ref _items, value);
            }
        }

        #endregion

        #region Constructors

        public UsersViewModel(INavigationService navigation, IUserDialogs dialogs) 
            : base(navigation, dialogs)
        {
            Navigation = navigation;
            _dialogs = dialogs;
        }

        public void Init(string docID)
        {
            _userList = _db.GetDocument(docID);
            SetupQuery();
            Filter(null);
        }

        #endregion

        #region Private API

        private void SelectList(KeyValuePair<string, UserCellModel> pair)
        {
            SelectedItem = pair.Value;
        }

        private async Task AddNewUser()
        {
            var result = await _dialogs.PromptAsync(new PromptConfig {
                Title = "New User",
                Placeholder = "User Name"
            });

            if(result.Ok) {
                try {
                    CreateNewUser(result.Text);
                } catch(Exception e) {
                    _dialogs.Toast(e.Message);
                }
            }
        }

        /// <summary>
        /// Creates a new user for the associated list
        /// </summary>
        /// <param name="username">The username to create.</param>
        public void CreateNewUser(string username)
        {
            var taskListInfo = new Dictionary<string, object>
            {
                ["id"] = _userList.Id,
                ["owner"] = _userList.GetString("owner")
            };

            var properties = new Dictionary<string, object>
            {
                ["type"] = UserType,
                ["taskList"] = taskListInfo,
                ["username"] = username
            };

            var docId = $"{_userList.Id}.{username}";
            try
            {
                var doc = new MutableDocument(docId, properties);
                _db.Save(doc);
                Filter(_searchUserName);
            }
            catch (Exception e)
            {
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
            if (!String.IsNullOrEmpty(searchString))
            {
                query = _filteredQuery;
                query.Parameters.SetString("searchText", $"%{searchString}%");
            }
            else
            {
                query = _fullQuery;
            }

            QueryRun(query);
        }

        #endregion

        #region Private API

        private void SetupQuery()
        {
            var username = Expression.Property("username");
            var exp1 = Expression.Property("type").EqualTo(Expression.String(UserType)); //"task-list.user"
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

            _usersLiveQuery.AddChangeListener((sender, args) =>
            {
                QueryRun(_usersLiveQuery);
            });
        }

        void QueryRun(IQuery query)
        {
            var results = query.Execute();
            var allResult = results.AllResults();
            if (allResult.Count < ListData.Count) {
                ListData = new ObservableConcurrentDictionary<string, UserCellModel>();
            }
            Task.Run(() =>
            {
                Parallel.ForEach(allResult, result =>
                {
                    var name = result.GetString("username");
                    var idKey = $"{_userList.Id}.{name}";

                    if (_items.ContainsKey(idKey)) {
                        _items[idKey].Name = name;
                    } else {
                        var user = new UserCellModel(_dialogs, idKey, ListData);
                        user.Name = name;
                        ListData.Add(idKey, user);
                    }

                });
            });
        }
        
        #endregion

    }
}

