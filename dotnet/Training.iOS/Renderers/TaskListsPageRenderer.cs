//
// Renderers.cs
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
using System.Collections.Generic;

using Training;
using Training.Forms;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;

[assembly: ExportRenderer(typeof(TaskListsPage), typeof(Training.iOS.TaskListsPageRenderer))]

namespace Training.iOS
{
    /// <summary>
    /// A custom renderer to allow specification of the left navigation button
    /// </summary>
    public sealed class TaskListsPageRenderer : PageRenderer
    {

        #region Overrides

        public override void MotionEnded(UIEventSubtype motion, UIEvent evt)
        {
            if(motion == UIEventSubtype.MotionShake) {
                // TRAINING: Create task list conflict (for development only)
                var page = this.Element as TaskListsPage;
                var vm = page?.BindingContext as TaskListsViewModel;
                vm?.TestConflict();
            }
        }

        public override void ViewWillAppear(bool animated)
        {
            base.ViewWillAppear(animated);

            var LeftNavList = new List<UIBarButtonItem>();
            var rightNavList = new List<UIBarButtonItem>();

            var navigationItem = this.NavigationController.TopViewController.NavigationItem;
            if(navigationItem.LeftBarButtonItems != null && navigationItem.LeftBarButtonItems.Length > 0) {
                // Already run, likely coming back from a navigation
                return;
            }

            var element = Element as ContentPage;
            for(var i = 0; i < element.ToolbarItems.Count; i++) {

                var reorder = (element.ToolbarItems.Count - 1);
                var ItemPriority = element.ToolbarItems[reorder - i].Priority;

                if(ItemPriority == 1) {
                    UIBarButtonItem LeftNavItems = navigationItem.RightBarButtonItems[i];
                    LeftNavList.Add(LeftNavItems);
                } else if(ItemPriority == 0) {
                    UIBarButtonItem RightNavItems = navigationItem.RightBarButtonItems[i];
                    rightNavList.Add(RightNavItems);
                }
            }

            navigationItem.SetLeftBarButtonItems(LeftNavList.ToArray(), false);
            navigationItem.SetRightBarButtonItems(rightNavList.ToArray(), false);
        }

        #endregion
    }
}

