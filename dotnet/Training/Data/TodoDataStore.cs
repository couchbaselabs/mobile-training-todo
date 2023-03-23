using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;
using Training.Utils;

namespace Training.Data
{
    public class TodoDataStore : IDataStore<TaskListItem>
    {
        #region Constants

        internal const string TaskType = "task-list";
        public static readonly string TaskListCollection = "lists";

        #endregion

        private Collection _collection = CoreApp.Database.GetCollection(TaskListCollection);
        private IQuery _fullQuery;
        private IQuery _incompleteQuery;
        private readonly ConcurrentDictionary<string, int> _incompleteCount = new ConcurrentDictionary<string, int>();
        private readonly IList<string> _jsons = new List<string>();

        /// <summary>
        /// Gets the username of the user using the app
        /// </summary>
        public string Username => CoreApp.Database?.Name;

        public ObservableConcurrentDictionary<string, TaskListItem> Data { get; private set; } = new ObservableConcurrentDictionary<string, TaskListItem>();

        public TodoDataStore()
        {
            SetupQuery();
            StartListeners();
        }

        public static void Prepare(Database db)
        {
            db.CreateCollection(TaskListCollection);
        }

        public async Task<bool> LoadItemsAsync(string id = null)
        {
            return await Task.FromResult(true);
        }

        public async Task<string> AddItemAsync(TaskListItem item)
        {
            var docId = $"{Username}.{Guid.NewGuid()}";

            try
            {
                using (var doc = new MutableDocument(docId))
                {
                    doc.SetString("type", TaskType);
                    doc.SetString("name", item.Name);
                    doc.SetString("owner", Username);
                    _collection.Save(doc);
                }

                //item.DocumentID = docId;
                //if(!Data.TryAdd(docId, item))
                //{
                //    return await Task.FromResult("Data Add Item failed.");
                //}
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        public async Task<string> UpdateItemAsync(TaskListItem item)
        {
            if (item.DocumentID == null)
            {
                return await Task.FromResult("The document id is null.");
            }

            try
            {
                using (var doc = _collection.GetDocument(item.DocumentID))
                using (var mdoc = doc.ToMutable())
                {
                    mdoc.SetString("type", TaskType);
                    mdoc.SetString("name", item.Name);
                    mdoc.SetString("owner", Username);
                    _collection.Save(mdoc);
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
            if (String.IsNullOrEmpty(id))
            {
                return null; //nothing to be deleted
            }

            try
            {
                using (var doc = _collection.GetDocument(id))
                {
                    _collection.Delete(doc);
                }

                //Data.TryRemove(id, out var tl);
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        public async Task<TaskListItem> GetItemAsync(string id)
        {
            Data.TryGetValue(id, out var tasklist);
            return await Task.FromResult(tasklist);
        }

        public async Task<ObservableConcurrentDictionary<string, TaskListItem>> GetItemsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(Data);
        }

        public async Task<IEnumerable<string>> ReturnJsonsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(_jsons);
        }

        public void Filter(string searchText)
        {
            var query = default(IQuery);
            if (!String.IsNullOrEmpty(searchText))
            {
                query = CoreApp.QueryDictionary[QueryType.FilteredQuery];
                query.Parameters.SetString("searchText", $"%{searchText}%");

                var results = query.Execute();
                var _ = ProcessQueryResults(results.AllResults());
            }
        }

        #region Private Methods

        private void SetupQuery()
        {
            _collection.CreateIndex("byName", IndexBuilder.ValueIndex(ValueIndexItem.Expression(Expression.Property("name"))));
            _fullQuery = CoreApp.QueryDictionary[QueryType.FullQuery];
            _incompleteQuery = CoreApp.QueryDictionary[QueryType.IncompleteQuery];
        }

        private void StartListeners()
        {
            _incompleteQuery.AddChangeListener((sender, args) =>
            {
                var results = args.Results.AllResults();
                if (results.Count != _incompleteCount.Count)
                {
                    _incompleteCount.Clear();
                }

                Parallel.ForEach(results, result =>
                    {
                        var key = result.GetString(0);
                        var value = result.GetInt(1);
                        _incompleteCount.AddOrUpdate(key, value,
                            (k, oldValue) =>
                            {
                                oldValue = value;
                                return oldValue;
                            });
                    });

                UpdateIncompleteCount();
            });

            _fullQuery.AddChangeListener(async (sender, args) =>
            {
                //run live query
                await ProcessQueryResults(args.Results.AllResults());
            });
        }

        private async Task<bool> ProcessQueryResults(IList<Result> allResult)
        {
            if (allResult.Count < Data.Count)
            {
                Data.Clear();
            }

            Parallel.ForEach(allResult, result =>
            {
                var idKey = result.GetString("id");
                var name = result.GetString("name");

                Data.AddOrUpdate(idKey,
                    (key) =>
                    {
                        var newVal = new TaskListItem();
                        newVal.DocumentID = idKey;
                        newVal.Name = name;
                        return newVal;
                    }, (key, oldVal) =>
                    {
                        oldVal.Name = name;
                        return oldVal;
                    });
            });

            UpdateIncompleteCount();

            return await Task.FromResult(true);
        }

        bool isBusy;
        private void UpdateIncompleteCount()
        {
            if (isBusy)
                return;
            isBusy = true;
            Parallel.ForEach(Data, item =>
            {
                if (_incompleteCount.ContainsKey(item.Key))
                {
                    item.Value.IncompleteCount = _incompleteCount[item.Key];
                }
                else
                {
                    item.Value.IncompleteCount = 0;
                }
            });
            isBusy = false;
        }

        #endregion
    }
}