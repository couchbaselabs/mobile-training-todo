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

using Acr.UserDialogs;
using Foundation;
using Robo.Mvvm;
using Training;
using Training.Core;

using UIKit;

using Xamarin.Forms.Platform.iOS;

namespace Training.iOS
{
    /// <summary>
    /// The app delegate for the overall iOS app lifecycle
    /// </summary>
    [Register("AppDelegate")]
    public partial class AppDelegate : FormsApplicationDelegate
    {

        #region Properties

        public override UIWindow Window
        {
            get;
            set;
        }

        #endregion

        #region Overrides

        public override bool FinishedLaunching(UIApplication app, NSDictionary options)
        {
            // Setup the application
            Xamarin.Forms.Forms.Init();

            // tag::activate[]
            Couchbase.Lite.Support.iOS.Activate();
            // end::activate[]

            RegisterServices();
            
            //Start the application
            LoadApplication(new App());

            return base.FinishedLaunching(app, options);
        }

        #endregion

        void RegisterServices()
        {
            ServiceContainer.Register<IImageService>(() => new ImageService());
        }

    }
}
