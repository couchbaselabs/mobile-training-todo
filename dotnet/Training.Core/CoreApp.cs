//
// CoreApp.cs
//
// Author:
// 	Jim Borden  <jim.borden@couchbase.com>
//
// Copyright (c) 2016 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
using System;
using Acr.UserDialogs;
using Couchbase.Lite;
using Couchbase.Lite.Auth;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;
using MvvmCross.Platform.IoC;
using XLabs.Platform.Device;
using XLabs.Platform.Services.Media;

namespace Training.Core
{
    /// <summary>
    /// This is the first location to be reached in the actual shared application
    /// </summary>
    public sealed class CoreApp : MvxApplication
    {
        public static readonly Manager AppWideManager = Manager.SharedInstance;
        private static readonly Uri SyncGatewayUrl = new Uri("http://localhost:4984/todo/");
        private static Replication _pusher;
        private static Replication _puller;

        public static void StartReplication(string username, string password = null)
        {
            var authenticator = default(IAuthenticator);
            if(username != null && password != null) {
                authenticator = AuthenticatorFactory.CreateBasicAuthenticator(username, password);
            }

            var db = AppWideManager.GetDatabase(username);
            _pusher = db.CreatePushReplication(SyncGatewayUrl);
            _pusher.Continuous = true;
            _pusher.Authenticator = authenticator;

            _puller = db.CreatePullReplication(SyncGatewayUrl);
            _puller.Continuous = true;
            _puller.Authenticator = authenticator;

            _pusher.Start();
            _puller.Start();
        }

        public override void Initialize()
        {
            CreatableTypes()
            .EndingWith("ViewModel")
            .AsTypes()
            .RegisterAsDynamic();

            Mvx.RegisterSingleton<IUserDialogs>(() => UserDialogs.Instance);
            Mvx.RegisterType<IMediaPicker>(() => Mvx.Resolve<IDevice>().MediaPicker);
            RegisterAppStart<TaskListsViewModel>();
        }
    }

    public sealed class CoreAppStart : MvxNavigatingObject, IMvxAppStart
    {
        public void Start(object hint = null)
        {
            dynamic h = hint;
            if(h.loginEnabled) {
                // Login logic
            } else {
                if(h.syncEnabled) {
                    CoreApp.StartReplication("todo");
                }

                ShowViewModel<TaskListsViewModel>(new { loginEnabled = false, username = "todo"});
            }
        }
    }
}

