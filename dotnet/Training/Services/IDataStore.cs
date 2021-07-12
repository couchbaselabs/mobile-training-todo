using MvvmHelpers;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace Training.Services
{
    public interface IDataStore<T>
    {
        event EventHandler DataHasChanged;
        void LoadItems(string id = null);
        Task<bool> AddItemAsync(T item);
        Task<bool> UpdateItemAsync(T item);
        Task<bool> DeleteItemAsync(string id);
        Task<T> GetItemAsync(string id);
        Task<IEnumerable<T>> GetItemsAsync(bool forceRefresh = false);
        Task<IEnumerable<string>> ReturnJsonsAsync(bool forceRefresh = false);
    }
}
