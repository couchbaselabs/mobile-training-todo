//
// AppDelegate.cs
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
using Foundation;
using MvvmCross.iOS.Platform;
using MvvmCross.Platform;
using Training.Core;
using UIKit;
using XLabs.Platform.Device;

namespace Training.iOS
{
    [Register("AppDelegate")]
    public partial class AppDelegate : MvxApplicationDelegate
    {
        public override UIWindow Window
        {
            get;
            set;
        }

        public override bool FinishedLaunching(UIApplication app, NSDictionary options)
        {
            // Setup the application
            Xamarin.Forms.Forms.Init();
            Window = new UIWindow(UIScreen.MainScreen.Bounds);
            var setup = new Setup(this, Window);
            setup.Initialize();

            // Couchbase requires plugin registration for any storage engine on iOS
            Couchbase.Lite.Storage.SystemSQLite.Plugin.Register();

            // Register platform specific implementations
            Mvx.RegisterSingleton<IDevice>(() => AppleDevice.CurrentDevice);
            Mvx.RegisterSingleton<IImageService>(() => new ImageService());

            //Start the application
            var startup = new CoreAppStart();
            startup.Start(new { loginEnabled = false, syncEnabled = true });

            Window.MakeKeyAndVisible();

            return true;
        }
    }
}
