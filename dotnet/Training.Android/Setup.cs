//
// Setup.cs
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
using Android.Content;
using MvvmCross.Droid.Platform;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform.Platform;
using MvvmCross.Droid.Views;
using MvvmCross.Platform;
using MvvmCross.Core.Views;
using MvvmCross.Forms.Platform;
using Training.Core;
using MvvmCross.Forms.Droid.Platform;
using Training.Forms;
using System.Reflection;
using MvvmCross.Platform.IoC;
using System.Linq;
using System;

namespace Training.Android
{
    /// <summary>
    /// Custom app setup (not much here)
    /// </summary>
    public sealed class Setup : MvxFormsAndroidSetup
    {
        public Setup(Context applicationContext) : base(applicationContext)
        {
        }

        protected override IMvxApplication CreateApp()
        {
            return new CoreApp();
        }

        protected override IMvxTrace CreateDebugTrace()
        {
            return new DebugTrace();
        }

        protected override MvxFormsApplication CreateFormsApplication()
        {
            return new App();
        }

        protected override IMvxAndroidViewsContainer CreateViewsContainer(Context applicationContext)
        {
            var viewsContainer = (IMvxViewsContainer)base.CreateViewsContainer(applicationContext);
            var viewModelTypes =
                typeof(LoginViewModel).GetTypeInfo().Assembly.CreatableTypes().Where(t => t.Name.EndsWith("ViewModel")).ToDictionary(t => t.Name.Remove(t.Name.LastIndexOf("ViewModel", StringComparison.Ordinal)));
            var viewTypes =
                typeof(LoginPage).GetTypeInfo().Assembly.CreatableTypes().Where(t => t.Name.EndsWith("Page")).ToDictionary(t => t.Name.Remove(t.Name.LastIndexOf("Page", StringComparison.Ordinal)));
            foreach (var viewModelTypeAndName in viewModelTypes)
            {
                Type viewType;
                if (viewTypes.TryGetValue(viewModelTypeAndName.Key, out viewType))
                    viewsContainer.Add(viewModelTypeAndName.Value, viewType);
            }

            return (IMvxAndroidViewsContainer)viewsContainer;
        }
    }
}