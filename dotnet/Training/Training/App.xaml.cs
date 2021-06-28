﻿using Couchbase.Lite;
using System;
using Training.Data;
using Xamarin.Forms;

namespace Training
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();

            CoreApp.Hint = new CoreAppStartHint
            {
                LoginEnabled = true,
                CCRType = CCR_TYPE.NONE,
                Heartbeat = TimeSpan.Zero,
                MaxRetries = -1,
                MaxRetryWaitTime = TimeSpan.Zero,
                IsDebugging = false,
                EncryptionEnabled = false,
                IsDatabaseChangeMonitoring = false,
                SyncEnabled = true,
                UsePrebuiltDB = false,
                Username = "todo"
            };

            if (CoreApp.Hint.IsDebugging)
            {//TODO: save logs as file to local path
                Database.Log.Console.Level = Couchbase.Lite.Logging.LogLevel.Info;
            }

            DependencyService.Register<TodoDataStore>();
            DependencyService.Register<TasksData>();
            DependencyService.Register<UsersData>();
            MainPage = new AppShell();
            if (!CoreApp.Hint.LoginEnabled)
            {
                CoreApp.StartSession(CoreApp.Hint.Username, null, null);
            } 
            else
            {
                Shell.Current.GoToAsync("//LoginPage");
            }
        }

        protected override void OnStart()
        {
        }

        protected override void OnSleep()
        {
        }

        protected override void OnResume()
        {
        }
    }
}
