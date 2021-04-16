using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using Training.Models;

namespace Training.Data
{
    public class TasksData
    {
        private IQuery _tasksFilteredQuery;
        private IQuery _tasksFullQuery;
        private Database _db = CoreApp.Database;
        private readonly ObservableCollection<TaskItem> _items;

        public string TaskListItemID { get; set; }

        public TasksData(string Id)
        {
            _items = new ObservableCollection<TaskItem>();
            TaskListItemID = Id;
        }

        public async Task<bool> AddItemAsync(TaskItem item)
        {
            _items.Add(item);

            return await Task.FromResult(true);
        }

        public async Task<bool> UpdateItemAsync(TaskItem item)
        {
            var oldItem = _items.Where((TaskItem arg) => arg.Name == item.Name).FirstOrDefault();
            _items.Remove(oldItem);
            _items.Add(item);

            return await Task.FromResult(true);
        }

        public async Task<bool> DeleteItemAsync(string name)
        {
            var oldItem = _items.Where((TaskItem arg) => arg.Name == name).FirstOrDefault();
            _items.Remove(oldItem);

            return await Task.FromResult(true);
        }

        public async Task<TaskItem> GetItemAsync(string name)
        {
            return await Task.FromResult(_items.FirstOrDefault(s => s.Name == name));
        }

        public async Task<IEnumerable<TaskItem>> GetItemsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(_items);
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

        private void SetupQuery()
        {
            _tasksFilteredQuery = QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String("task"))
                    .And(Expression.Property("taskList.id").EqualTo(Expression.String(TaskListItemID)))
                    .And(Expression.Property("task").Like(Expression.Parameter("searchString"))))
                .OrderBy(Ordering.Property("createdAt"));

            _tasksFullQuery = QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String("task"))
                    .And(Expression.Property("taskList.id").EqualTo(Expression.String(TaskListItemID))));

            _tasksFullQuery.AddChangeListener((sender, args) =>
            {
                //run live query
                RunQuery(args.Results.AllResults());
            });
        }

        private void RunQuery(List<Result> allResult)
        {
            if (allResult.Count < _items.Count)
            {
                _items.Clear();
            }

            Task.Run(() =>
            {
                Parallel.ForEach(allResult, result =>
                {
                    var idKey = result.GetString("id");
                    var document = _db.GetDocument(idKey);
                    if (!idKey.Equals(document.Id))
                        return;
                    var name = document.GetString("task");
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
                            var task = new TaskItem() { DocumentID = idKey };
                            task.Name = name;
                            _items.Add(task);
                        }
                    }
                });
            });
        }
    }
}
