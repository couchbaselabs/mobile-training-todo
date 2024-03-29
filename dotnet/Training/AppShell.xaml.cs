﻿using Training.Views;

namespace Training;

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
        Routes.Add(nameof(TaskDetailPage), typeof(TaskDetailPage));
        Routes.Add(nameof(UserDetailPage), typeof(UserDetailPage));
        Routes.Add(nameof(TaskListDetailPage), typeof(TaskListDetailPage));
        Routes.Add(nameof(ToJSONPage), typeof(ToJSONPage));

        foreach (var item in Routes) {
            Routing.RegisterRoute(item.Key, item.Value);
        }
    }

    private async void OnMenuItemClicked(object sender, EventArgs e)
    {
        await Current.GoToAsync("//LoginPage");
    }
}
