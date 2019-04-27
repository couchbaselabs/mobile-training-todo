//
// TasksViewModel.cs
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
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;

using Couchbase.Lite;
using Couchbase.Lite.Query;

using Prototype.Mvvm.Input;
using Prototype.Mvvm.Services;

using Training.Core;
using Training.Core.Services;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for the list of tasks page
    /// </summary>
    public class TasksViewModel : BaseNavigationViewModel, IDisposable
    {

        #region Constants

        internal const string TaskType = "task";

        #endregion

        #region Variables

        private readonly IUserDialogs _dialogs;
        private readonly INavigationService _navigationService;
        private readonly ImageChooser _imageChooser;
        private readonly IMediaService _mediaService;

        private IQuery _tasksFilteredQuery;
        private IQuery _tasksFullQuery;
        private Database _db = CoreApp.Database;
        private Document _taskList;

        #endregion

        #region Properties

        /// <summary>
        /// Gets or sets the currently selected item in the table view
        /// </summary>
        /// <value>The selected item.</value>
        public TaskCellModel SelectedItem
        {
            get => _selectedItem;
            set {
                if(_selectedItem == value) {
                    return;
                }

                _selectedItem = value;
                value.IsChecked = !value.IsChecked;
                SetPropertyChanged(ref _selectedItem, null);
            }
        }
        private TaskCellModel _selectedItem;

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
        /// Gets the command that is fired when the add button is pressed
        /// </summary>
        /// <value>The add command.</value>
        public ICommand AddCommand => new Command(() => AddNewItem());

        ICommand _selectCommand;
        public ICommand SelectCommand
        {
            get
            {
                if (_selectCommand == null)
                {
                    _selectCommand = new Command<KeyValuePair<string, TaskCellModel>>((pair) => SelectList(pair));
                }

                return _selectCommand;
            }
        }

        /// <summary>
        /// Gets the list of tasks for display in the list view
        /// </summary>
        /// <value>The list data.</value>
        ObservableConcurrentDictionary<string, TaskCellModel> _items = new ObservableConcurrentDictionary<string, TaskCellModel>();
        public ObservableConcurrentDictionary<string, TaskCellModel> ListData
        {
            get { return _items; }
            set {
                _items = value;
                SetPropertyChanged(ref _items, value);
            }
        }

        /// <summary>
        /// Gets the name of the database being worked on
        /// </summary>
        public string DatabaseName => _db.Name;

        #endregion

        #region Constructors

        public TasksViewModel(INavigationService navigationService, IUserDialogs dialogs) 
            : base(navigationService, dialogs)
        {
            _dialogs = dialogs;
            _navigationService = navigationService;

            _imageChooser = new ImageChooser(new ImageChooserConfig
            {
                Dialogs = _dialogs
            });

            //ListData.CollectionChanged += (sender, e) =>
            //{
            //    if (e.NewItems == null)
            //    {
            //        return;
            //    }

            //    UpdateButtons(e.NewItems);
            //};

            //UpdateButtons(ListData);
            
        }

        public void Init(string docID)
        {
            _taskList = _db.GetDocument(docID);
            SetupQuery();
            Filter(null);
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="parent">The parent view model (this is a nested view model).</param>
        //public TasksViewModel(ListDetailViewModel parent) : base(new TasksModel(parent.CurrentListID))
        //{
        //    _dialogs = Mvx.Resolve<IUserDialogs>();
        //    _imageChooser = new ImageChooser(new ImageChooserConfig {
        //        Dialogs = _dialogs
        //    });

        //    ListData.CollectionChanged += (sender, e) => 
        //    {
        //        if(e.NewItems == null) {
        //            return;
        //        }

        //        UpdateButtons(e.NewItems);
        //    };

        //    UpdateButtons(ListData);
        //}

        #endregion

        #region Internal API

        internal async Task ShowOrChooseImage(TaskCellModel taskDocument)
        {
            if(!taskDocument.HasImage()) {
                await ChooseImage(taskDocument);
            } else {
                //ShowViewModel<TaskImageViewModel>(new { documentID = taskDocument.DocumentID });
            }
        }

        #endregion

        #region Private API

        private void SelectList(KeyValuePair<string, TaskCellModel> pair)
        {
            SelectedItem = pair.Value;
        }

        private void UpdateButtons(IList newItems)
        {
            foreach (TaskCellModel item in newItems) {
                if (item.AddImageCommand == null) {
                    //item.AddImageCommand = new MvxAsyncCommand<TaskCellModel>(ShowOrChooseImage);
                }
            }
        }

        private async Task ChooseImage(TaskCellModel taskCellModel)
        {
            var result = await _imageChooser.GetPhotoAsync();
            if(result == null) {
                return;
            }

            if(result == Stream.Null) {
                result = null;
            }

            try {
                taskCellModel.SetImage(result);
            } catch(Exception e) {
                _dialogs.Toast(e.Message);
                return;
            }
        }
    
        private void AddNewItem()
        {
            _dialogs.Prompt(new PromptConfig {
                OnAction = CreateNewItem,
                Title = "New Task",
                Placeholder = "Task Name"
            });
        }

        private void CreateNewItem(PromptResult result)
        {
            if(!result.Ok) {
                return;
            }

            try {
                CreateNewTask(result.Text);
            } catch(Exception e) {
                _dialogs.Toast(e.Message);
            }
        }

        /// <summary>
        /// Creates a new task in the current list
        /// </summary>
        /// <param name="taskName">The name of the task</param>
        public Document CreateNewTask(string taskName)
        {
            var taskListInfo = new Dictionary<string, object>
            {
                ["id"] = _taskList.Id,
                ["owner"] = _taskList.GetString("owner")
            };

            var properties = new Dictionary<string, object>
            {
                ["type"] = TaskType,
                ["taskList"] = taskListInfo,
                ["createdAt"] = DateTimeOffset.UtcNow,
                ["task"] = taskName,
                ["complete"] = false
            };

            try
            {
                var doc = new MutableDocument(properties);
                _db.Save(doc);
                Filter(null);
                return doc;
            }
            catch (Exception e)
            {
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
            if (!String.IsNullOrEmpty(searchString))
            {
                query = _tasksFilteredQuery;
                query.Parameters.SetString("searchString", $"%{searchString}%");
            }
            else
            {
                query = _tasksFullQuery;
            }

            var results = query.Execute();

            var allResult = results.AllResults();
            if (allResult.Count < ListData.Count) {
                ListData = new ObservableConcurrentDictionary<string, TaskCellModel>();
            }
            Parallel.For(0, allResult.Count, i =>
            {
                var result = allResult[i];
                var idKey = result.GetString("id");
                var document = _db.GetDocument(idKey);
                var name = document.GetString("task");
                if (name == null) {
                    _db.Delete(document);
                } else {
                    if (_items.ContainsKey(idKey)) {
                        _items[idKey].Name = name;
                    } else {
                        var task = new TaskCellModel(_navigationService, _dialogs, _mediaService, idKey);
                        task.StatusUpdated += Task_StatusUpdated;
                        ListData.Add(idKey, task);
                    }
                }
            });
        }

        private void Task_StatusUpdated(object sender, State state)
        {
            TaskCellModel listCell = (TaskCellModel)sender;
            if (state == State.DELETED)
                ListData.Remove(listCell.DocumentID);
        }

        private void SetupQuery()
        {
            _tasksFilteredQuery = QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String(TaskType))
                    .And(Expression.Property("taskList.id").EqualTo(Expression.String(_taskList.Id)))
                    .And(Expression.Property("task").Like(Expression.Parameter("searchString"))))
                .OrderBy(Ordering.Property("createdAt"));

            _tasksFullQuery = QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String(TaskType))
                    .And(Expression.Property("taskList.id").EqualTo(Expression.String(_taskList.Id))))
                .OrderBy(Ordering.Property("createdAt"));
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            ListData = new ObservableConcurrentDictionary<string, TaskCellModel>();
            _tasksFilteredQuery.Dispose();
            _tasksFullQuery.Dispose();

        }

        #endregion
    }
}

