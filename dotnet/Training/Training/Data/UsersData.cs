using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using Training.Models;

namespace Training.Data
{
    public class UsersData
    {
        public readonly ObservableCollection<User> Items;

        public UsersData(string Id)
        {
            Items = new ObservableCollection<User>();

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Afghan Hound" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Alpine Dachsbracke" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "American Bulldog" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Bearded Collie" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Boston Terrier" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Canadian Eskimo" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Eurohound" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Irish Terrier" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Kerry Beagle" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Norwegian Buhund" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Patterdale Terrier" + Id
            });

            Items.Add(new User
            {
                Id = Guid.NewGuid().ToString(),
                Name = "St. Bernard" + Id
            });
        }

        public async Task<bool> AddItemAsync(User item)
        {
            Items.Add(item);

            return await Task.FromResult(true);
        }

        public async Task<bool> DeleteItemAsync(string id)
        {
            var oldItem = Items.Where((User arg) => arg.Id == id).FirstOrDefault();
            Items.Remove(oldItem);

            return await Task.FromResult(true);
        }

        public async Task<User> GetItemAsync(string id)
        {
            return await Task.FromResult(Items.FirstOrDefault(s => s.Id == id));
        }

        public async Task<IEnumerable<User>> GetItemsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(Items);
        }

        public async Task<bool> UpdateItemAsync(User item)
        {
            var oldItem = Items.Where((User arg) => arg.Id == item.Id).FirstOrDefault();
            Items.Remove(oldItem);
            Items.Add(item);

            return await Task.FromResult(true);
        }
    }
}


