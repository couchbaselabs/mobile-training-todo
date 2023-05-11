using Training.Utils;

namespace Training.Services
{
    public interface IDataStore<T>
    {
        ObservableConcurrentDictionary<string, T> Data { get; }
        Task<bool> LoadItemsAsync(string id = null);
        Task<string> AddItemAsync(T item);
        Task<string> UpdateItemAsync(T item);
        Task<string> DeleteItemAsync(string id);
        Task<T> GetItemAsync(string id);
        //Task<ConcurrentDictionary<string, T>> GetItemsAsync(bool forceRefresh = false);
        Task<IEnumerable<string>> ReturnJsonsAsync(bool forceRefresh = false);
    }
}
