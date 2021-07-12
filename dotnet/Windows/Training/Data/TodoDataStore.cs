using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;

namespace Training.Data
{
    public class TodoDataStore : IDataStore<TaskListItem>
    {
        #region Constants

        internal const string TaskType = "task-list";

        #endregion

        Database _db = CoreApp.Database;
        private IQuery _fullQuery;
        private IQuery _incompleteQuery;
        private IDictionary<string, int> _incompleteCount = new Dictionary<string, int>();
        private readonly IList<TaskListItem> _items = new List<TaskListItem>();
        private readonly IList<string> _jsons = new List<string>();

        /// <summary>
        /// Gets the username of the user using the app
        /// </summary>
        public string Username => _db?.Name;

        public TodoDataStore()
        {
            SetupQuery();
            var results = _fullQuery.Execute();
            LoadTaskLists(results.AllResults()).ConfigureAwait(false);
            StartQueryListeners().ConfigureAwait(false);
        }

        public void LoadItems(string id = null)
        {
        }

        public async Task<bool> AddItemAsync(TaskListItem item)
        {
            var docId = $"{Username}.{Guid.NewGuid()}";
            try
            {
                using (var doc = new MutableDocument(docId))
                {
                    doc.SetString("type", TaskType);
                    doc.SetString("name", item.Name);
                    doc.SetString("owner", Username);
                    _db.Save(doc);
                }

                //item.DocumentID = docId;
                //_items.Add(item);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't save task list", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<bool> UpdateItemAsync(TaskListItem item)
        {
            if(item.DocumentID == null)
            {
                return false;
            }

            try
            {
                using (var doc = _db.GetDocument(item.DocumentID))
                using (var mdoc = doc.ToMutable())
                {
                    mdoc.SetString("type", TaskType);
                    mdoc.SetString("name", item.Name);
                    mdoc.SetString("owner", Username);
                    _db.Save(mdoc);
                }

                //var oldItem = _items.Where((TaskListItem arg) => arg.DocumentID == item.DocumentID).FirstOrDefault();
                //_items.Remove(oldItem);
                //_items.Add(item);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't save task list", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<bool> DeleteItemAsync(string id)
        {
            if (String.IsNullOrEmpty(id))
            {
                return true; //nothing to be deleted
            }

            try
            {
                using (var doc = _db.GetDocument(id))
                {
                    _db.Delete(doc);
                }

                var oldItem = await GetItemAsync(id);
                _items.Remove(oldItem);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't delete task list", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<TaskListItem> GetItemAsync(string id)
        {
            return await Task.FromResult(_items.FirstOrDefault(s => s.DocumentID == id));
        }

        public async Task<IEnumerable<TaskListItem>> GetItemsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(_items);
        }

        public async Task<IEnumerable<string>> ReturnJsonsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(_jsons);
        }

        public async Task Filter(string searchText)
        {
            var query = default(IQuery);
            if (!String.IsNullOrEmpty(searchText))
            {
                query = CoreApp.QueryDictionary[QueryType.FilteredQuery];
                query.Parameters.SetString("searchText", $"%{searchText}%");

                var results = query.Execute();
                await LoadTaskLists(results.AllResults());
            }
        }

        #region Private Methods

        private void SetupQuery()
        {
            _db.CreateIndex("byName", IndexBuilder.ValueIndex(ValueIndexItem.Expression(Expression.Property("name"))));
            _fullQuery = CoreApp.QueryDictionary[QueryType.FullQuery];
            _incompleteQuery = CoreApp.QueryDictionary[QueryType.IncompleteQuery];
        }

        private async Task StartQueryListeners()
        {
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
                    });

                    Parallel.ForEach(_items, item =>
                    {
                        if (_incompleteCount.ContainsKey(item.DocumentID))
                        {
                            item.IncompleteCount = _incompleteCount[item.DocumentID];
                        }
                        else
                        {
                            item.IncompleteCount = 0;
                        }
                    });
                });
            });

            _fullQuery.AddChangeListener(async (sender, args) =>
            {
                //run live query
                await LoadTaskLists(args.Results.AllResults());
            });
        }

        private async Task LoadTaskLists(IList<Result> allResult)
        {
            await Task.Run(() =>
            {
                if (allResult.Count() < _items.Count)
                {
                    _items.Clear();
                }

                foreach (var result in allResult)
                {
                    var idKey = result.GetString("id");
                    using (var document = _db.GetDocument(idKey))
                    {
                        var name = result.GetString("name");
                        if (name == null)
                        {
                            _db.Delete(document);
                        }
                        else
                        {
                            var item = _items.Where(x => x.DocumentID == idKey).SingleOrDefault();
                            if (item != null)
                            {
                                item.Name = name;
                            }
                            else
                            {
                                _items.Add(new TaskListItem()
                                {
                                    DocumentID = idKey,
                                    Name = name
                                });
                            }
                        }
                    }
                }
            });
        }

        #endregion
    }
}