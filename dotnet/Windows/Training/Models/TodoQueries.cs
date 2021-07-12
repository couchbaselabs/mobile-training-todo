using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Text;

namespace Training.Models
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
            QueryDictionary.Add(QueryType.FilteredQuery, QueryBuilder.Select(SelectResult.Expression(Meta.ID),
                    SelectResult.Expression(Expression.Property("name")))
                    .From(DataSource.Database(_db))
                    .Where(Expression.Property("name")
                        .Like(Expression.Parameter("searchText"))
                        .And(Expression.Property("type").EqualTo(Expression.String("task-list"))))
                    .OrderBy(Ordering.Property("name")));

            QueryDictionary.Add(QueryType.FullQuery, QueryBuilder.Select(SelectResult.Expression(Meta.ID),
                    SelectResult.Expression(Expression.Property("name")))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("name")
                    .NotNullOrMissing()
                    .And(Expression.Property("type").EqualTo(Expression.String("task-list"))))
                .OrderBy(Ordering.Property("name")));

            QueryDictionary.Add(QueryType.IncompleteQuery, QueryBuilder.Select(SelectResult.Expression(Expression.Property("taskList.id")),
                    SelectResult.Expression(Function.Count(Expression.All())))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String("task"))
                       .And(Expression.Property("complete").EqualTo(Expression.Boolean(false))))
                .GroupBy(Expression.Property("taskList.id")));

            QueryDictionary.Add(QueryType.TasksFilteredQuery, QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String("task"))
                    .And(Expression.Property("taskList.id").EqualTo(Expression.Parameter("taskListId")))
                    .And(Expression.Property("task").Like(Expression.Parameter("searchString"))))
                .OrderBy(Ordering.Property("createdAt")));

            QueryDictionary.Add(QueryType.TasksFullQuery, QueryBuilder.Select(SelectResult.Expression(Meta.ID))
                .From(DataSource.Database(_db))
                .Where(Expression.Property("type").EqualTo(Expression.String("task"))
                    .And(Expression.Property("taskList.id").EqualTo(Expression.Parameter("taskListId")))));

            var username = Expression.Property("username");
            var exp1 = Expression.Property("type").EqualTo(Expression.String("task-list.user"));
            var exp2 = Expression.Property("taskList.id").EqualTo(Expression.Parameter("taskListId"));

            QueryDictionary.Add(QueryType.UsersFilteredQuery, QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Database(_db))
                .Where(username
                    .Like(Expression.Parameter("searchText"))
                    .And((exp1).And(exp2)))
                .OrderBy(Ordering.Property("username")));

            QueryDictionary.Add(QueryType.UsersFullQuery, QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Database(_db))
                .Where(username
                    .NotNullOrMissing()
                    .And((exp1).And(exp2)))
                .OrderBy(Ordering.Property("username")));

            QueryDictionary.Add(QueryType.UsersLiveQuery, QueryBuilder.Select(SelectResult.Expression(username))
                .From(DataSource.Database(_db))
                .Where((exp1).And(exp2)).OrderBy(Ordering.Property("username")));
        }
    }
}
