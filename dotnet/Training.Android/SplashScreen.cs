//
// SplashScreen.cs
//
// Author:
//  Jim Borden  <jim.borden@couchbase.com>
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
using Android.App;
using Android.Content.PM;
using Android.OS;
using MvvmCross.Droid.Views;
using Xamarin.Forms;

namespace Training.Android
{
    /// <summary>
    /// The first activity in the application, shown while Xamarin Forms
    /// is initializing
    /// </summary>
    [Activity(
        Label = "Todo"
        , MainLauncher = true
        , Theme = "@style/Theme.Splash"
        , NoHistory = true
        , Icon = "@mipmap/icon"
        , ScreenOrientation = ScreenOrientation.Portrait)]
    public class SplashScreen : MvxSplashScreenActivity
    {

        #region Variables

        private bool isInitializationComplete = false;

        #endregion

        #region Constructors

        public SplashScreen()
            : base(Resource.Layout.SplashScreen)
        {
        }

        #endregion

        #region Overrides

        public override void InitializationComplete()
        {
            if(!isInitializationComplete) {
                isInitializationComplete = true;
                StartActivity(typeof(MvxFormsApplicationActivity));
            }
        }

        protected override void OnCreate(Bundle bundle)
        {
            Xamarin.Forms.Forms.Init(this, bundle);
            // Leverage controls' StyleId attrib. to Xamarin.UITest
            Xamarin.Forms.Forms.ViewInitialized += (object sender, ViewInitializedEventArgs e) =>
            {
                if(!string.IsNullOrWhiteSpace(e.View.StyleId)) {
                    e.NativeView.ContentDescription = e.View.StyleId;
                }
            };

            base.OnCreate(bundle);
        }

        #endregion
    }
}