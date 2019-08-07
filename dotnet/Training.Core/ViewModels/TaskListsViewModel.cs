//
// TaskListsViewModel.cs
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
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;

using Couchbase.Lite;
using Couchbase.Lite.Query;
using Robo.Mvvm;
using Robo.Mvvm.Input;
using Robo.Mvvm.Services;
using Robo.Mvvm.ViewModels;
using Training.Core;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for the list of task lists page
    /// </summary>
    public class TaskListsViewModel : BaseNavigationViewModel
    {
        #region Constants

        private const string TaskListType = "task-list";

        #endregion

        #region Variables

        private Database _db = CoreApp.Database;
        private IQuery _filteredQuery;
        private IQuery _fullQuery;
        private IQuery _incompleteQuery;
        private IDictionary<string, int> _incompleteCount = new Dictionary<string, int>();

        #endregion

        #region Properties

        /// <summary>
        /// Gets whether or not login is enabled
        /// </summary>
        public bool LoginEnabled
        {
            get; private set;
        }

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

        /// <summary>
        /// Gets or sets the currently selected item in the page list
        /// </summary>
        /// <value>The selected item.</value>
        public TaskListCellModel SelectedItem
        {
            get {
                return _selectedItem;
            }
            set {
                _selectedItem = value;
                SetPropertyChanged(ref _selectedItem, null); // No "selection" effect
                if(value != null)
                {
                    var vm = GetViewModel<ListDetailViewModel>();
                    vm.Init(Username, value.Name, value.DocumentID, Navigation);
                    Navigation.PushModalAsync(vm);
                }
            }
        }
        private TaskListCellModel _selectedItem;

        /// <summary>
        /// Gets the list of task lists for display in the list view
        /// </summary>
        ObservableConcurrentDictionary<string, TaskListCellModel> _items = new ObservableConcurrentDictionary<string, TaskListCellModel>();
        public ObservableConcurrentDictionary<string, TaskListCellModel> Items
        {
            get { return _items; }
            set {
                _items = value;
                SetPropertyChanged(ref _items, value);
            }
        }

        /// <summary>
        /// Gets the username of the user using the app
        /// </summary>
        public string Username => _db?.Name;

        /// <summary>
        /// Gets the command that is fired when the add button is pressed
        /// </summary>
        public ICommand AddCommand => new Command(() => AddNewItem());

        public ICommand LogoutCommand => new Command(() => Logout());

        ICommand _selectCommand;
        public ICommand SelectCommand
        {
            get
            {
                if (_selectCommand == null)
                {
                    _selectCommand = new Command<KeyValuePair<string, TaskListCellModel>>((pair) => SelectList(pair));
                }

                return _selectCommand;
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor, not to be called directly.
        /// </summary>
        /// <param name="dialogs">The interface responsible for displaying dialogs (from IoC container)</param>
        public TaskListsViewModel(INavigationService navigation, IUserDialogs dialogs) : base(navigation, dialogs)
        {
            Navigation = navigation;
            Dialogs = dialogs;
            SetupQuery();
        }

        #endregion

        #region Public API

        /// <summary>
        /// Initializes the view model with data passed to it
        /// </summary>
        /// <param name="loginEnabled">If set to <c>true</c> login is enabled in the application</param>
        public void Init(bool loginEnabled)
        {
            LoginEnabled = loginEnabled;
        }

        #endregion

        #region Private API

        private void SelectList(KeyValuePair<string, TaskListCellModel> pair)
        {
            SelectedItem = pair.Value;
        }

        private void AddNewItem()
        {
            Dialogs.Prompt(new PromptConfig {
                OnAction = CreateNewItem,
                Title = "New Task List",
                Placeholder = "List Name"
            });
        }

        private void Logout()
        {
            CoreApp.EndSession();
            Navigation.SetRoot(ServiceContainer.GetInstance<LoginViewModel>(), false);
        }

        private void CreateNewItem(PromptResult result)
        {
            if(!result.Ok) {
                return;
            }

            try {
                CreateTaskList(result.Text);
            } catch(Exception e) {
                Dialogs.Toast(e.Message);
            }
        }

        #endregion

        /// <summary>
        /// Creates a new task list
        /// </summary>
        /// <param name="taskListName">The name of the task list.</param>
        public Document CreateTaskList(string taskListName)
        {
            var docId = $"{Username}.{Guid.NewGuid()}";
            try {
                var doc = new MutableDocument(docId);
                doc["type"].Value = TaskListType;
                doc["name"].Value = taskListName;
                doc["owner"].Value = Username;
                _db.Save(doc);
                return doc;
            } catch (Exception e) {
                var newException = new Exception("Couldn't save task list", e);
                throw newException;
            }
        }

        public void Filter(string searchText)
        {
            var query = default(IQuery);
            if (!String.IsNullOrEmpty(searchText)) {
                query = _filteredQuery;
                query.Parameters.SetString("searchText", $"%{searchText}%");

                var results = query.Execute();
                RunQuery(results.AllResults());
            }
        }
        
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

            _fullQuery.AddChangeListener((sender, args) =>
            {
                //run live query
                RunQuery(args.Results.AllResults());
            });

            _incompleteQuery = QueryBuilder.Select(SelectResult.Expression(Expression.Property("taskList.id")),
                    SelectResult.Expression(Function.Count(Expression.All())))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String(TasksViewModel.TaskType))
                       .And(Expression.Property("complete").EqualTo(Expression.Boolean(false))))
                .GroupBy(Expression.Property("taskList.id"));
            _incompleteQuery.AddChangeListener((sender, args) =>
            {
                Task.Run(() =>
                {
                    _incompleteCount = new Dictionary<string, int>();
                    Parallel.ForEach(args.Results, result =>
                    {
                        var key = result.GetString(0);
                        var value = result.GetInt(1);
                        var document = _db.GetDocument(key);
                        if (document == null)
                            return;
                        var name = document.GetString("name");

                        _incompleteCount.Add(key, value);

                        if (!_items.ContainsKey(key)) {
                            var task = new TaskListCellModel(Navigation, Dialogs, key, name, Items);
                            task.IncompleteCount = value;
                            Items.Add(key, task);
                        }
                    });

                    Parallel.ForEach(Items.Keys, key =>
                    {
                        var value = Items[key];
                        if (_incompleteCount.ContainsKey(key)) {
                            value.IncompleteCount = _incompleteCount[key];
                        } else {
                            value.IncompleteCount = 0;
                        }
                    });
                });
            });
        }

        private void RunQuery(List<Result> allResult)
        {
            if (allResult.Count < Items.Count) {
                _items = new ObservableConcurrentDictionary<string, TaskListCellModel>();
            }
            Task.Run(() =>
            {
                Parallel.ForEach(allResult, result =>
                {
                    var idKey = result.GetString("id");
                    var document = _db.GetDocument(idKey);
                    var name = result.GetString("name");
                    if (name == null) {
                        _db.Delete(document);
                    } else {
                        if (_items.ContainsKey(idKey)) {
                            _items[idKey].Name = name;
                        } else {
                            var task = new TaskListCellModel(Navigation, Dialogs, idKey, name, Items);
                            Items.Add(idKey, task);
                        }
                    }
                });
            });
        }

        #endregion

    }
}

