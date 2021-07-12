using Couchbase.Lite;
using Couchbase.Lite.Query;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Training.Models;
using Training.Services;
using Xamarin.Forms;

namespace Training.Data
{
    public class UsersData : IDataStore<User>
    {
        #region Constants

        private const string UserType = "task-list.user";

        #endregion

        private Database _db = CoreApp.Database;
        private IQuery _filteredQuery;
        private IQuery _fullQuery;
        private IQuery _usersLiveQuery;
        private string _searchUserName;
        private readonly IList<User> _users = new List<User>();
        private IList<string> _listenerStarted = new List<string>();
        private string _taskListId;

        public event EventHandler DataHasChanged;

        public void LoadItems(string listId)
        {
            _taskListId = listId;
            SetupQuery(listId);
            QueryRun(_usersLiveQuery);
            if (!_listenerStarted.Contains(listId))
            {
                StartListener();
                _listenerStarted.Add(listId);
            }
        }

        public async Task<bool> AddItemAsync(User user)
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
                ["type"] = UserType,
                ["taskList"] = taskListInfo,
                ["username"] = user.Name
            };

            var docId = $"{_taskListId}.{user.Name}";
            try
            {
                using (var doc = new MutableDocument(docId, properties))
                {
                    _db.Save(doc);
                }

                Filter(_searchUserName);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't create user", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<bool> DeleteItemAsync(string id)
        {
            var user = await GetItemAsync(id);
            if (user == null)
            {
                return true; //nothing to be deleted
            }

            try
            {
                using (var doc = _db.GetDocument(user.DocumentID))
                {
                    _db.Delete(doc);
                }

                _users.Remove(user);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't delete user", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
        }

        public async Task<User> GetItemAsync(string id)
        {
            return await Task.FromResult(_users.FirstOrDefault(s => s.DocumentID == id));
        }

        public async Task<IEnumerable<User>> GetItemsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(_users);
        }



        public Task<IEnumerable<string>> ReturnJsonsAsync(bool forceRefresh = false)
        {
            throw new NotImplementedException();
        }

        public async Task<bool> UpdateItemAsync(User user)
        {
            try
            {
                using (var doc = _db.GetDocument(user.DocumentID))
                using (var mdoc = doc.ToMutable())
                {
                    mdoc.SetString("username", user.Name);
                    _db.Save(mdoc);
                }

                var oldItem = await GetItemAsync(user.DocumentID);
                _users.Remove(oldItem);
                _users.Add(user);
            }
            catch (Exception e)
            {
                var newException = new Exception("Couldn't update user", e);
                return await Task.FromResult(false);
            }

            return await Task.FromResult(true);
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
            _filteredQuery = CoreApp.QueryDictionary[QueryType.UsersFilteredQuery];
            _filteredQuery.Parameters.SetString("taskListId", listId);
            _fullQuery = CoreApp.QueryDictionary[QueryType.UsersFullQuery];
            _fullQuery.Parameters.SetString("taskListId", listId);
            _usersLiveQuery = CoreApp.QueryDictionary[QueryType.UsersLiveQuery];
            _usersLiveQuery.Parameters.SetString("taskListId", listId);
        }

        private void StartListener()
        {
            _usersLiveQuery.AddChangeListener((sender, args) =>
            {
                QueryRun(_usersLiveQuery);
            });
        }

        private void QueryRun(IQuery query)
        {
            var results = query.Execute();
            var allResult = results.AllResults();
            if (allResult.Count() < _users.Count || (_users.Count > 0 && _users[0].TaskListID != _taskListId))
            {
                _users.Clear();
            }

            foreach (var result in allResult)
            {
                var name = result.GetString("username");
                var idKey = $"{_taskListId}.{name}";
                using (var document = _db.GetDocument(idKey))
                {
                    if (!idKey.Equals(document.Id))
                        return;

                    var user = GetItemAsync(idKey).Result;

                    if (user != null)
                    {
                        user.TaskListID = _taskListId;
                        user.Name = name;
                    }
                    else
                    {
                        _users.Add(new User()
                        {
                            TaskListID = _taskListId,
                            DocumentID = idKey,
                            Name = name
                        });
                    }
                }
            }

            DataHasChanged?.Invoke(this, null);
        }
    }
}


