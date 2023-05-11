using Couchbase.Lite;
using Couchbase.Lite.Query;

namespace Training.Data
{
    public enum QueryType
    {
        FullQuery,
        IncompleteQuery,
        FilteredQuery,
        TasksFullQuery,
        TasksFilteredQuery,
        UsersFilteredQuery,
        UsersFullQuery,
        UsersLiveQuery
    }

    internal class TodoQueries
    {
        Database _db = CoreApp.Database;
        public Dictionary<QueryType, IQuery> QueryDictionary { get; } = new Dictionary<QueryType, IQuery>();

        internal TodoQueries()
        {
            QueryDictionary.Add(QueryType.FilteredQuery, 
                _db.CreateQuery($"SELECT meta().id, name FROM {TodoDataStore.TaskListCollection} WHERE name LIKE $searchText ORDER BY name"));

            QueryDictionary.Add(QueryType.FullQuery,
                _db.CreateQuery($"SELECT meta().id, name FROM {TodoDataStore.TaskListCollection} WHERE name IS VALUED ORDER BY name"));

            QueryDictionary.Add(QueryType.IncompleteQuery, QueryBuilder.Select(SelectResult.Expression(Expression.Property("taskList.id")),
                    SelectResult.Expression(Function.Count(Expression.All())))
                .From(DataSource.Collection(_db.GetCollection(TasksData.TaskCollection)))
                .Where(Expression.Property("complete").EqualTo(Expression.Boolean(false)))
                .GroupBy(Expression.Property("taskList.id")));

            QueryDictionary.Add(QueryType.TasksFilteredQuery,
                _db.CreateQuery($"SELECT meta().id FROM {TasksData.TaskCollection} WHERE taskList.id = $taskListId AND task LIKE $searchString ORDER BY createdAt"));

            QueryDictionary.Add(QueryType.TasksFullQuery,
                _db.CreateQuery($"SELECT meta().id, task, complete, image FROM {TasksData.TaskCollection} WHERE taskList.id = $taskListId ORDER BY createdAt"));

            var username = Expression.Property("username");
            var exp1 = Expression.Property("taskList.id").EqualTo(Expression.Parameter("taskListId"));

            QueryDictionary.Add(QueryType.UsersFilteredQuery, QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Collection(_db.GetCollection(UsersData.UserCollection)))
                .Where(username
                    .Like(Expression.Parameter("searchText"))
                    .And(exp1))
                .OrderBy(Ordering.Property("username")));

            QueryDictionary.Add(QueryType.UsersFullQuery, QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Collection(_db.GetCollection(UsersData.UserCollection)))
                .Where(username
                    .IsValued()
                    .And(exp1))
                .OrderBy(Ordering.Property("username")));

            QueryDictionary.Add(QueryType.UsersLiveQuery, QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Collection(_db.GetCollection(UsersData.UserCollection)))
                .Where(exp1).OrderBy(Ordering.Property("username")));
        }
    }
}
