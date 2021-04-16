using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using Training.Models;

namespace Training.Services
{
    public class TodoDataStore : IDataStore<TaskListItem>
    {
        Database _db = CoreApp.Database;
        private IQuery _filteredQuery;
        private IQuery _fullQuery;
        private IQuery _incompleteQuery;
        private IDictionary<string, int> _incompleteCount = new Dictionary<string, int>();
        private readonly ObservableCollection<TaskListItem> _items;
        private readonly ObservableCollection<string> _jsons;

        /// <summary>
        /// Gets the username of the user using the app
        /// </summary>
        public string Username => _db?.Name;

        public TodoDataStore()
        {
            _items = new ObservableCollection<TaskListItem>();
            _jsons = new ObservableCollection<string>();
            SetupQuery();
        }

        public async Task<bool> AddItemAsync(TaskListItem item)
        {
            var docId = $"{Username}.{Guid.NewGuid()}";
            try
            {
                using (var doc = new MutableDocument(docId))
                {
                    doc.SetString("type", "task-list");
                    doc.SetString("name", item.Name);
                    doc.SetString("owner", Username);
                    _db.Save(doc);
                }
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't save task list", e);
                throw newException;
            }

            item.DocumentID = docId;
            _items.Add(item);

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
                    mdoc.SetString("type", "task-list");
                    mdoc.SetString("name", item.Name);
                    mdoc.SetString("owner", Username);
                    _db.Save(mdoc);
                }
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't save task list", e);
                throw newException;
            }

            var oldItem = _items.Where((TaskListItem arg) => arg.DocumentID == item.DocumentID).FirstOrDefault();
            _items.Remove(oldItem);
            _items.Add(item);

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
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't save task list", e);
                throw newException;
            }

            var oldItem = _items.Where((TaskListItem arg) => arg.DocumentID == id).FirstOrDefault();
            _items.Remove(oldItem);

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

        public void Filter(string searchText)
        {
            var query = default(IQuery);
            if (!String.IsNullOrEmpty(searchText))
            {
                query = _filteredQuery;
                query.Parameters.SetString("searchText", $"%{searchText}%");

                var results = query.Execute();
                LoadTaskLists(results.AllResults());
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
                LoadTaskLists(args.Results.AllResults());
            });

            _incompleteQuery = QueryBuilder.Select(SelectResult.Expression(Expression.Property("taskList.id")),
                    SelectResult.Expression(Function.Count(Expression.All())))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String("task"))
                       .And(Expression.Property("complete").EqualTo(Expression.Boolean(false))))
                .GroupBy(Expression.Property("taskList.id"));
            _incompleteQuery.AddChangeListener((sender, args) =>
            {
                _incompleteCount = new Dictionary<string, int>();
                foreach (var result in args.Results)
                {
                    var key = result.GetString(0);
                    var value = result.GetInt(1);
                    var document = _db.GetDocument(key);
                    if (document == null)
                        return;

                    var name = document.GetString("name");
                    _incompleteCount.Add(key, value);
                    var item = _items.Where(x => x.DocumentID == key).SingleOrDefault();
                    if (item == null)
                    {
                        var task = new TaskListItem() { DocumentID = key, Name = name };
                        task.IncompleteCount = value;
                        _items.Add(task);
                    }
                };

                foreach (var item in _items)
                {
                    if (_incompleteCount.ContainsKey(item.DocumentID))
                    {
                        item.IncompleteCount = _incompleteCount[item.DocumentID];
                    }
                    else
                    {
                        item.IncompleteCount = 0;
                    }
                };

            });
        }

        private void LoadTaskLists(List<Result> allResult)
        {
            _jsons.Clear();
            if (allResult.Count < _items.Count)
            {
                _items.Clear();
            }

            foreach (var result in allResult)
            {
                _jsons.Add(result.ToJSON());
                var idKey = result.GetString("id");
                var document = _db.GetDocument(idKey);
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
                        var task = new TaskListItem() { DocumentID = idKey, Name = name };
                        _items.Add(task);
                    }
                }
            };

        }

        #endregion
    }
}