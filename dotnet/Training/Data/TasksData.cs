﻿using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;
using Training.Utils;

namespace Training.Data
{
    public class TasksData : IDataStore<TaskItem>
    {
        #region Constants

        internal const string TaskType = "task";

        #endregion

        private Database _db = CoreApp.Database;
        private string _taskListId;
        private IQuery _tasksFilteredQuery;
        private IQuery _tasksFullQuery;

        public ObservableConcurrentDictionary<string, TaskItem> Data { get; private set; }

        public TasksData()
        {
            Data = new ObservableConcurrentDictionary<string, TaskItem>();
            _tasksFilteredQuery = CoreApp.QueryDictionary[QueryType.TasksFilteredQuery];
            _tasksFullQuery = CoreApp.QueryDictionary[QueryType.TasksFullQuery];
            StartListener();
        }

        public async Task<bool> LoadItemsAsync(string listId = null)
        {
            if (_taskListId != listId)
            {
                _taskListId = listId;
                SetupQuery(listId);
                var results = _tasksFullQuery.Execute();
                ProcessQueryResults(results.AllResults());
            }

            return await Task.FromResult(true);
        }

        public async Task<string> AddItemAsync(TaskItem item)
        {
            Dictionary<string, object> properties;
            using (var doc = _db.GetDocument(_taskListId))
            {
                var taskListInfo = new Dictionary<string, object>
                {
                    ["id"] = _taskListId,
                    ["owner"] = doc.GetString("owner")
                };

                properties = new Dictionary<string, object>
                {
                    ["type"] = TaskType,
                    ["taskList"] = taskListInfo,
                    ["createdAt"] = DateTimeOffset.UtcNow,
                    ["task"] = item.Name,
                    ["complete"] = false
                };
            }

            try
            {
                using (var doc = new MutableDocument(properties))
                {
                    if (item.Thumbnail != null)
                    {
                        var blob = new Blob("image/png", item.Thumbnail);
                        doc.SetBlob("image", blob);
                    }
                    else
                    {
                        doc.Remove("image");
                    }

                    _db.Save(doc);
                    //item.DocumentID = doc.Id;
                    //Data.Add(doc.Id, item);
                }
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        public async Task<string> UpdateItemAsync(TaskItem item)
        {
            try
            {
                using (var doc = _db.GetDocument(item.DocumentID))
                using (var mdoc = doc.ToMutable())
                {
                    mdoc.SetString(TaskType, item.Name);
                    mdoc.SetBoolean("complete", item.IsChecked);
                    if (item.Thumbnail != null)
                    {
                        var blob = new Blob("image/png", item.Thumbnail);
                        mdoc.SetBlob("image", blob);
                    }
                    else
                    {
                        mdoc.Remove("image");
                    }

                    _db.Save(mdoc);
                }

                //Data.Remove(item.DocumentID);
                //Data.Add(item.DocumentID, item);
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        public async Task<string> DeleteItemAsync(string id)
        {
            var item = await GetItemAsync(id);
            if (item == null)
            {
                return null; //nothing to be deleted
            }

            try
            {
                using (var doc = _db.GetDocument(item.DocumentID))
                {
                    _db.Delete(doc);
                }

                //Data.TryRemove(id, out var tl);
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        public async Task<TaskItem> GetItemAsync(string id)
        {
            Data.TryGetValue(id, out var task);
            return await Task.FromResult(task);
        }

        public Task<IEnumerable<string>> ReturnJsonsAsync(bool forceRefresh = false)
        {
            throw new NotImplementedException();
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

                var results = query.Execute();
                ProcessQueryResults(results.AllResults());
            }
        }

        private void SetupQuery(string listId)
        {
            _tasksFilteredQuery.Parameters.SetString("taskListId", listId);
            _tasksFullQuery.Parameters.SetString("taskListId", listId);
        }

        private void StartListener()
        {
            _tasksFullQuery.AddChangeListener((sender, args) =>
            {
                ProcessQueryResults(args.Results.AllResults());
            });
        }

        private void ProcessQueryResults(IList<Result> allResult)
        {
            if (allResult.Count() != Data.Count || (Data.Count > 0 && Data.First().Key != _taskListId))
            {
                Data.Clear();
            }

            Parallel.ForEach(allResult, result =>
            {
                var idKey = result.GetString("id");
                using (var document = _db.GetDocument(idKey))
                {
                    if (!idKey.Equals(document.Id))
                        return;

                    var name = document.GetString("task");
                    if (name == null)
                    {
                        _db.Delete(document);
                    }
                    else
                    {
                        Data.AddOrUpdate(idKey, new TaskItem()
                        {
                            TaskListID = _taskListId,
                            DocumentID = idKey,
                            Name = name,
                            Thumbnail = document.GetBlob("image")?.Content,
                            IsChecked = document.GetBoolean("complete")
                        },
                        (key, oldVal) =>
                        {
                            oldVal.Name = name;
                            oldVal.TaskListID = _taskListId;
                            return oldVal;
                        });
                    }
                }
            });
        }
    }
}
