using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Diagnostics;
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
        public static readonly string TaskCollection = "tasks";

        #endregion

        private Collection _tasksCollection = CoreApp.Database.GetCollection(TaskCollection);
        private Collection _taskListsCollection = CoreApp.Database.GetCollection(TodoDataStore.TaskListCollection);
        private string _taskListId;
        private IQuery _tasksFilteredQuery;
        private IQuery _tasksFullQuery;
        private ListenerToken? _currentListener;

        public ObservableConcurrentDictionary<string, TaskItem> Data { get; private set; }

        public TasksData()
        {
            Data = new ObservableConcurrentDictionary<string, TaskItem>();
            _tasksFilteredQuery = CoreApp.QueryDictionary[QueryType.TasksFilteredQuery];
            _tasksFullQuery = CoreApp.QueryDictionary[QueryType.TasksFullQuery];
        }

        public static void Prepare(Database db)
        {
            db.CreateCollection(TaskCollection);
        }

        public async Task<bool> LoadItemsAsync(string listId = null)
        {
            if (_taskListId != listId)
            {
                _taskListId = listId;
                SetupQuery(listId);
                StartListener();
                var results = _tasksFullQuery.Execute();
                Debug.WriteLine("_tasksFullQuery processed from LoadItemsAsync!");
                await ProcessQueryResults(results.AllResults());
            }

            return await Task.FromResult(true);
        }

        public async Task<string> AddItemAsync(TaskItem item)
        {
            Dictionary<string, object> properties;
            using (var doc = _taskListsCollection.GetDocument(_taskListId))
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

                    _tasksCollection.Save(doc);
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
            if (item.DocumentID == null)
            {
                return await Task.FromResult("The document id is null.");
            }

            try
            {
                using (var doc = _tasksCollection.GetDocument(item.DocumentID))
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

                    _tasksCollection.Save(mdoc);
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
                using (var doc = _tasksCollection.GetDocument(item.DocumentID))
                {
                    _tasksCollection.Delete(doc);
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
            if (!String.IsNullOrEmpty(searchString))
            {
                var query = _tasksFilteredQuery;
                query.Parameters.SetString("searchString", $"%{searchString}%");
                var results = query.Execute();
                var _ = ProcessQueryResults(results.AllResults());
            }
        }

        private void SetupQuery(string listId)
        {
            _tasksFilteredQuery.Parameters.SetString("taskListId", listId);
            _tasksFullQuery.Parameters.SetString("taskListId", listId);
        }

        private void StartListener()
        {
            _currentListener?.Remove();
            _currentListener = _tasksFullQuery.AddChangeListener(async (sender, args) =>
            {
                await ProcessQueryResults(args.Results.AllResults());
            });
        }

        private async Task<bool> ProcessQueryResults(IList<Result> allResult)
        {
            if (allResult.Count < Data.Count || (Data.Count > 0 && Data.First().Key != _taskListId))
            {
                Data.Clear();
            }

            Parallel.ForEach(allResult, result =>
              {
                  var idKey = result.GetString("id");
                  var name = result.GetString("task");
                  var image = result.GetBlob("image");
                  var isCompleted = result.GetBoolean("complete");

                  try
                  {
                      Data.AddOrUpdate(idKey,
                          (k) =>
                          {
                              var newVal = new TaskItem();
                              newVal.TaskListID = _taskListId;
                              newVal.DocumentID = idKey;
                              newVal.Name = name;
                              newVal.Thumbnail = image?.Content;
                              newVal.IsChecked = isCompleted;
                              return newVal;
                          },
                          (k, oldVal) =>
                          {
                              oldVal.TaskListID = _taskListId;
                              oldVal.Name = name;
                              oldVal.Thumbnail = image?.Content;
                              oldVal.IsChecked = isCompleted;
                              return oldVal;
                          });
                  }
                  catch (Exception ex)
                  {
                      Debug.WriteLine("TasksData ProcessQueryResults Exception: " + ex.Message + " Inner Exception: " + ex.InnerException?.Message);
                  }
              });

            return await Task.FromResult(true);
        }
    }
}
