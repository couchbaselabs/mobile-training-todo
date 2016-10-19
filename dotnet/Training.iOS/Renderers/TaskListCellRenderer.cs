//
// TaskListCellRenderer.cs
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
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;
using UIKit;
using Training.Forms;
using Foundation;

[assembly: ExportRenderer(typeof(TaskListCell), typeof(Training.iOS.TaskListCellRenderer))]

namespace Training.iOS
{
    /// <summary>
    /// A custom renderer for a list view cell on iOS (to show the detail disclosure)
    /// </summary>
    public class TaskListCellRenderer : ViewCellRenderer
    {

        #region Constants

        private static readonly NSString rid = new NSString("TaskListCell");

        #endregion

        #region Overrides

        public override UITableViewCell GetCell(Cell item, UITableViewCell reusableCell, UITableView tv)
        {
            var x = (TaskListCell)item;
            var cell = reusableCell;
            if(cell == null) {
                cell = new UITableViewCell(UITableViewCellStyle.Value1, rid);
            }

            cell.TextLabel.Text = x.Name;
            cell.DetailTextLabel.Text = x.IncompleteTasks;
            cell.Accessory = UITableViewCellAccessory.DisclosureIndicator;
            return cell;
        }

        #endregion

    }
}

