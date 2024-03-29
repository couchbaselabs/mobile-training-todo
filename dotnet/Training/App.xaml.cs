﻿using Couchbase.Lite;
using Training.Services;

namespace Training;

public partial class App : Application
{
	public App()
	{
		InitializeComponent();

        CoreApp.Hint = new CoreAppStartHint
        {
            LoginEnabled = true,
            CCRType = CCR_TYPE.NONE,
            Heartbeat = null,
            MaxRetries = 0,
            MaxRetryWaitTime = null,
            IsDebugging = false,
            EncryptionEnabled = false,
            IsDatabaseChangeMonitoring = false,
            SyncEnabled = false,
            UsePrebuiltDB = false,
            Username = "todo"
        };

        if (CoreApp.Hint.IsDebugging) {//TODO: save logs as file to local path
            Database.Log.Console.Level = Couchbase.Lite.Logging.LogLevel.Info;
        }

        MainPage = new AppShell();

        if (!CoreApp.Hint.LoginEnabled) {
            try {
                CoreApp.StartSession(CoreApp.Hint.Username, null, null);
            } catch (Exception e) {
                DependencyService.Get<IDisplayAlert>().DisplayAlertAsync("Enter Task Lists page Error", $"Error occurred, code = {e}", "Cancel");
                return;
            }
        } else {
            Shell.Current.GoToAsync("//LoginPage");
        }
    }
}
