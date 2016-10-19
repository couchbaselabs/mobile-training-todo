//
// TaskListCell.cs
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

using Xamarin.Forms;

namespace Training.Forms
{
    /// <summary>
    /// A view for a row in the TaskListsPage table (consumed per platform)
    /// </summary>
    public sealed class TaskListCell : ViewCell
    {

        #region Properties

        /// <summary>
        /// Bindable property for <see cref="Name"/> 
        /// </summary>
        public static readonly BindableProperty NameProperty =
            BindableProperty.Create("Name", typeof(string), typeof(TaskListCell), "");

        /// <summary>
        /// Gets or sets the name of the task list
        /// </summary>
        public string Name
        {
            get {
                return (string)GetValue(NameProperty);
            }
            set {
                SetValue(NameProperty, value);
            }
        }

        /// <summary>
        /// Bindable property for <see cref="IncompleteTasks"/> 
        /// </summary>
        public static readonly BindableProperty IncompleteTasksProperty =
            BindableProperty.Create("IncompleteTasks", typeof(string), typeof(TaskListCell), "");

        /// <summary>
        /// Gets or sets the number of incomplete tasks for this task list (as a string)
        /// </summary>
        public string IncompleteTasks
        {
            get {
                return (string)GetValue(IncompleteTasksProperty);
            }
            set {
                SetValue(IncompleteTasksProperty, value);
            }
        }

        #endregion

    }
}


