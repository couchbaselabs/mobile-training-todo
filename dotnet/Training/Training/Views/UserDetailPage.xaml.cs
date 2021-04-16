using System;
using System.Linq;
using Xamarin.Forms;
using Training.Data;
using Training.Models;

namespace Training.Views
{
    [QueryProperty(nameof(Name), "name")]
    public partial class UserDetailPage : ContentPage
    {
        public string Name
        {
            set
            {
                LoadUserDetail(value);
            }
        }

        public UserDetailPage()
        {
            InitializeComponent();
        }

        void LoadUserDetail(string name)
        {
            try
            {
                //User user = UsersData.Users.FirstOrDefault(a => a.Name == name);
                //BindingContext = user;
            }
            catch (Exception)
            {
                Console.WriteLine("Failed to load animal.");
            }
        }
    }
}
