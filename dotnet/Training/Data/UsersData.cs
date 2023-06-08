using Couchbase.Lite;
using Couchbase.Lite.Query;
using Training.Models;
using Training.Services;
using Training.Utils;

namespace Training.Data
{
    public class UsersData : IDataStore<User>
    {
        #region Constants

        private const string UserType = "task-list.user";
        public static readonly string UserCollection = "users";

        #endregion

        private Collection _usersCollection = CoreApp.Database.GetCollection(UserCollection);
        private Collection _taskListsCollection = CoreApp.Database.GetCollection(TodoDataStore.TaskListCollection);
        private IQuery _filteredQuery;
        private IQuery _fullQuery;
        private IQuery _usersLiveQuery;
        private string _searchUserName;
        private string _taskListId;
        private ListenerToken? _currentListener;

        public ObservableConcurrentDictionary<string, User> Data { get; private set; }

        public UsersData()
        {
            Data = new ObservableConcurrentDictionary<string, User>();
            _filteredQuery = CoreApp.QueryDictionary[QueryType.UsersFilteredQuery]; 
            _fullQuery = CoreApp.QueryDictionary[QueryType.UsersFullQuery]; 
            _usersLiveQuery = CoreApp.QueryDictionary[QueryType.UsersLiveQuery];
        }

        public static void Prepare(Database db)
        {
            db.CreateCollection(UserCollection);
        }

        public async Task<bool> LoadItemsAsync(string listId)
        {
            if (_taskListId != listId)
            {
                _taskListId = listId;
                SetupQuery(listId);
                StartListener();
                QueryRun(_usersLiveQuery);
            }

            return await Task.FromResult(true);
        }

        public async Task<string> AddItemAsync(User user)
        {
            string owner;
            using (var doc = _taskListsCollection.GetDocument(_taskListId))
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
                ["type"] = UserType,
                ["taskList"] = taskListInfo,
                ["username"] = user.Name
            };

            var docId = $"{_taskListId}.{user.Name}";
            try
            {
                using (var doc = new MutableDocument(docId, properties))
                {
                    _usersCollection.Save(doc);
                    //user.DocumentID = docId;
                    //Data.Add(doc.Id, user);
                }

                Filter(_searchUserName);
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        public async Task<string> DeleteItemAsync(string id)
        {
            var user = await GetItemAsync(id);
            if (user == null)
            {
                return null; //nothing to be deleted
            }

            try
            {
                using (var doc = _usersCollection.GetDocument(user.DocumentID))
                {
                    _usersCollection.Delete(doc);
                }

                Data.TryRemove(id, out var u);
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        public async Task<User> GetItemAsync(string id)
        {
            Data.TryGetValue(id, out var user);
            return await Task.FromResult(user);
        }

        public IEnumerable<string> GetJson(string parameter)
        {
            throw new NotImplementedException();
        }

        public async Task<string> UpdateItemAsync(User user)
        {
            try
            {
                using (var doc = _usersCollection.GetDocument(user.DocumentID))
                using (var mdoc = doc.ToMutable())
                {
                    mdoc.SetString("username", user.Name);
                    _usersCollection.Save(mdoc);
                }

                //Data.Remove(user.DocumentID);
                //Data.Add(user.DocumentID, user);
            }
            catch (Exception e)
            {
                return await Task.FromResult($"{e.Message}/Inner Exception {e.InnerException?.Message}");
            }

            return await Task.FromResult<string>(null);
        }

        /// <summary>
        /// Filters the users list based on a given string
        /// </summary>
        /// <param name="searchString">The string to filter on.</param>
        public void Filter(string searchString)
        {
            _searchUserName = searchString;
            var query = default(IQuery);
            if (!String.IsNullOrEmpty(searchString))
            {
                query = _filteredQuery;
                query.Parameters.SetString("searchText", $"%{searchString}%");
            }
            else
            {
                query = _fullQuery;
            }

            QueryRun(query);
        }

        private void SetupQuery(string listId)
        {
             _filteredQuery.Parameters.SetString("taskListId", listId);
            _fullQuery.Parameters.SetString("taskListId", listId);
            _usersLiveQuery.Parameters.SetString("taskListId", listId);
        }

        private void StartListener()
        {
            _currentListener?.Remove();
            _currentListener = _usersLiveQuery.AddChangeListener((sender, args) =>
            {
                QueryRun(_usersLiveQuery);
            });
        }

        private void QueryRun(IQuery query)
        {
            var results = query.Execute();
            var allResult = results.AllResults();

            if (allResult.Count() != Data.Count || (Data.Count > 0 && Data.First().Key != _taskListId))
            {
                Data.Clear();
            }

            Parallel.ForEach(allResult, result =>
            {
                var name = result.GetString("username");
                var idKey = $"{_taskListId}.{name}";
                using (var document = _usersCollection.GetDocument(idKey))
                {
                    if (!idKey.Equals(document.Id))
                        return;

                    var user = GetItemAsync(idKey).Result;
                    Data.AddOrUpdate(idKey, new User()
                    {
                        TaskListID = _taskListId,
                        DocumentID = idKey,
                        Name = name
                    },
                    (key, oldVal) =>
                    {
                        oldVal.TaskListID = _taskListId;
                        oldVal.Name = name;
                        return oldVal;
                    });
                }
            });
        }
    }
}


