using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json.Serialization;
using Training.Data;
using Training.Models;
using Training.Services;

namespace Training.ViewModels
{
    internal class RoleListContent
    {
        [JsonPropertyName("admin_channels")]
        public List<string> AdminChannels { get; set; } = new();

        public RoleListContent(List<string> adminChannels)
        {
            AdminChannels = adminChannels;
        }
    }

    internal class RoleCreationData
    {
        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("collection_access")]
        public Dictionary<string, Dictionary<string, RoleListContent>> CollectionAccess { get; set; } = new();

        public RoleCreationData(string name)
        {
            Name = name;
        }

        public void AddRoleListContent(string scope, string collection, List<string> adminChannels)
        {
            if (!CollectionAccess.TryGetValue(scope, out var scopeData)) {
                scopeData = new Dictionary<string, RoleListContent>();
                CollectionAccess.Add(scope, scopeData);
            }

            scopeData[collection] = new RoleListContent(adminChannels);
        }
    }

    [QueryProperty(nameof(ListItemId), nameof(ListItemId))]
    public class TaskListDetailViewModel : BaseViewModel
    {
        private bool _isEditing;
        private string _toJSONString;
        private string _id;
        private string _taskListName;
        private TaskListItem _taskListItem = new TaskListItem();
        private static HttpClient _httpClient = new();


        static TaskListDetailViewModel()
        {
            var auth = Convert.ToBase64String(Encoding.ASCII.GetBytes("admin:password"));
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", auth);
        }

        public string ListItemId 
        {
            get => _id;
            set
            {
                if (_id == value)
                    return;

                _id = value;
                if (!String.IsNullOrEmpty(ListItemId))
                {
                    IsEditing = true;
                    _taskListItem = DataStore.GetItemAsync(ListItemId).Result;
                    TaskListName = _taskListItem.Name;
                    using (var doc = CoreApp.Database.GetCollection(TodoDataStore.TaskListCollection).GetDocument(ListItemId))
                    {
                        ToJSONString = doc.ToJSON();
                    }
                }
            }
        }

        public string TaskListName
        {
            get => _taskListName;
            set
            {
                SetProperty(ref _taskListName, value);
                _taskListItem.Name = _taskListName;
            }
        }

        public bool IsEditing
        {
            get => _isEditing;
            set
            {
                SetProperty(ref _isEditing, value);
                if(_isEditing)
                    Title = "Edit Task List";
                else
                    Title = "New Task List";
            }
        }

        public string ToJSONString 
        {
            get => _toJSONString;
            set => SetProperty(ref _toJSONString, value);
        }

        public Command SaveCommand { get; }
        public Command CancelCommand { get; }

        public TaskListDetailViewModel()
        {
            SaveCommand = new Command(OnSave, ValidateSave);
            CancelCommand = new Command(OnCancel);
            this.PropertyChanged +=
                (_, __) => SaveCommand.ChangeCanExecute();
        }

        private bool ValidateSave()
        {
            return !String.IsNullOrWhiteSpace(TaskListName);
        }

        private async void OnCancel()
        {
            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }

        private RoleCreationData CreateRequestData(string taskListID)
        {
            var roleID = $"lists.{taskListID}.contributor";
            var retVal = new RoleCreationData(roleID);
            retVal.AddRoleListContent("_default", "lists", new List<string>());
            retVal.AddRoleListContent("_default", "tasks", new List<string>());
            retVal.AddRoleListContent("_default", "users", new List<string>());
            return retVal;
        }

        private async void OnSave()
        {
            if (IsEditing)
            {
                await DataStore.UpdateItemAsync(_taskListItem);
            }
            else
            {
                var res = await DataStore.AddItemAsync(_taskListItem);
                if(res != null)
                {
                    await DependencyService.Get<IDisplayAlert>().DisplayAlertAsync("Add Error", $"Couldn't add task list {_taskListItem.Name}: {res}", "OK");
                }

                await _httpClient.PostAsync(new Uri(CoreApp.SyncGatewayAdminUrl, "todo/_role/"), JsonContent.Create(CreateRequestData(_taskListItem.DocumentID)));
            }

            // This will pop the current page off the navigation stack
            await Shell.Current.GoToAsync("..");
        }
    }
}
