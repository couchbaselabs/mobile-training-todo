//
//  App.xaml.cs
//
//  Author:
//  	Jim Borden  <jim.borden@couchbase.com>
//
//  Copyright (c) 2016 Couchbase, Inc All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

using System;
using System.Windows;

using Acr.UserDialogs;
using MvvmCross.Platform;
using Training.Core;
using Training.WPF.Services;
using XLabs.Platform.Device;

namespace Training.WPF
{
    /// <summary>
    /// The overall application logic class (WPF high level)
    /// </summary>
    public partial class App : Application
    {

        #region Variables

        private bool _setupComplete;

        #endregion

        #region Private API

        private void DoSetup()
        {
            LoadMvxAssemblyResources();

            var presenter = new WpfPresenter(MainWindow);

            var setup = new Setup(Dispatcher, presenter);
            setup.Initialize();

            UserDialogs.Instance = new UserDialogsImpl();
            Mvx.RegisterSingleton<IImageService>(() => new ImageService());
            Mvx.RegisterSingleton<IDevice>(new Device());

            var start = new CoreAppStart();
            var hint = CoreAppStart.CreateHint();
            start.Start(hint);

            _setupComplete = true;
        }

        private void LoadMvxAssemblyResources()
        {
            for(var i = 0; ; i++) {
                var key = "MvxAssemblyImport" + i;
                var data = TryFindResource(key);
                if(data == null) {
                    return;
                }
            }
        }

        private void OnStartup(object sender, StartupEventArgs e)
        {
            if(e.Args.Length > 0 && e.Args[0].ToLowerInvariant() == "/clean") {
                CoreApp.AppWideManager.DeleteDatabase("todo");
            }
        }

        #endregion

        #region Overrides

        protected override void OnActivated(EventArgs e)
        {
            if(!_setupComplete) {
                DoSetup();
            }

            base.OnActivated(e);
        }

        #endregion

    }
}