using System;
using System.Collections.Generic;
using Training.Views;
using Xamarin.Forms;

namespace Training
{
    public partial class AppShell : Shell
    {
        public Dictionary<string, Type> Routes { get; private set; } = new Dictionary<string, Type>();
        public AppShell()
        {
            InitializeComponent();
            RegisterRoutes();
            BindingContext = this;
        }

        void RegisterRoutes()
        {
            Routes.Add(nameof(TaskListItemPage), typeof(TaskListItemPage));
            Routes.Add(nameof(TaskDetailPage), typeof(TaskDetailPage));
            Routes.Add(nameof(UserDetailPage), typeof(UserDetailPage));
            Routes.Add(nameof(NewTaskListItemPage), typeof(NewTaskListItemPage));
            Routes.Add(nameof(ToJSONPage), typeof(ToJSONPage));

            foreach (var item in Routes)
            {
                Routing.RegisterRoute(item.Key, item.Value);
            }
        }

        private async void OnMenuItemClicked(object sender, EventArgs e)
        {
            await Shell.Current.GoToAsync("//LoginPage");
        }
    }
}
