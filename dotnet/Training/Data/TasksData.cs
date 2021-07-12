using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;

namespace Training.Data
{
    public class TasksData : IDataStore<TaskItem>
    {
        #region Constants

        internal const string TaskType = "task";

        #endregion

        private string _taskListId;
        private IQuery _tasksFilteredQuery;
        private IQuery _tasksFullQuery;
        private Database _db = CoreApp.Database;
        private readonly IList<TaskItem> _tasks = new List<TaskItem>();
        private IList<string> _listenerStarted = new List<string>();

        public event EventHandler DataHasChanged;

        public void LoadItems(string listId = null)
        {
            _taskListId = listId;
            SetupQuery(listId);
            var results = _tasksFullQuery.Execute();
            RunQuery(results.AllResults());
            if (!_listenerStarted.Contains(listId))
            {
                StartListener();
                _listenerStarted.Add(listId);
            }
        }

        public async Task<bool> AddItemAsync(TaskItem item)
        {
            string owner;
            using (var doc = _db.GetDocument(_taskListId))
            {
                owner = doc.GetString("owner");
            }
            
            var taskListInfo = new Dictionary<string, object>
            {
                ["id"] = _taskListId,
                ["owner"] = owner
            };

            var properties = new Dictionary<string, object>
            {
                ["type"] = TaskType,
                ["taskList"] = taskListInfo,
                ["createdAt"] = DateTimeOffset.UtcNow,
                ["task"] = item.Name,
                ["complete"] = false
            };

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
                }

                //_tasks.Add(item);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't save task", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<bool> UpdateItemAsync(TaskItem item)
        {
            try
            {
                using(var doc = _db.GetDocument(item.DocumentID))
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

                var oldItem = await GetItemAsync(item.DocumentID);
                _tasks.Remove(oldItem);
                _tasks.Add(item);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't update task", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<bool> DeleteItemAsync(string id)
        {
            var item = await GetItemAsync(id);
            if (item == null)
            {
                return true; //nothing to be deleted
            }

            try
            {
                using (var doc = _db.GetDocument(item.DocumentID))
                {
                    _db.Delete(doc);
                }

                _tasks.Remove(item);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't delete task", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<TaskItem> GetItemAsync(string id)
        {
            return await Task.FromResult(_tasks.FirstOrDefault(s => s.DocumentID == id));
        }

        public async Task<IEnumerable<TaskItem>> GetItemsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(_tasks);
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
                RunQuery(results.AllResults());
            }
        }

        private void SetupQuery(string listId)
        {
            _tasksFilteredQuery = CoreApp.QueryDictionary[QueryType.TasksFilteredQuery];
            _tasksFilteredQuery.Parameters.SetString("taskListId", listId);
            _tasksFullQuery = CoreApp.QueryDictionary[QueryType.TasksFullQuery];
            _tasksFullQuery.Parameters.SetString("taskListId", listId);
        }

        private void StartListener()
        {
            _tasksFullQuery.AddChangeListener((sender, args) =>
            {
                //run live query
                RunQuery(args.Results.AllResults());
            });
        }

        private void RunQuery(IList<Result> allResult)
        {
            var allResultCnt = allResult.Count();
            int datasCnt = 0;
            if (allResultCnt < _tasks.Count || (_tasks.Count > 0 && _tasks[0].TaskListID != _taskListId))
            {
                _tasks.Clear();
            }

            foreach (var result in allResult)
            {
                if (allResultCnt > 20)
                    datasCnt++;
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
                        var task = GetItemAsync(idKey).Result;
                        if (task != null)
                        {
                            task.TaskListID = _taskListId;
                            task.Name = name;
                        }
                        else
                        {
                            _tasks.Add(new TaskItem()
                            {
                                TaskListID = _taskListId,
                                DocumentID = idKey,
                                Name = name,
                                Thumbnail = document.GetBlob("image")?.Content,
                                IsChecked = document.GetBoolean("complete")
                            });
                        }
                    }
                }

                if (allResultCnt > 20 && datasCnt == 10)
                {
                    DataHasChanged?.Invoke(this, null);
                    datasCnt = 0;
                }
                else
                {
                    DataHasChanged?.Invoke(this, null);
                }
            }

            if(allResultCnt > 20)
                DataHasChanged?.Invoke(this, null);
        }
    }
}
