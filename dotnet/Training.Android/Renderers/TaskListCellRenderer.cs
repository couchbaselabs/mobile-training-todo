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
using Android.App;
using Android.Content;
using Android.Views;
using Android.Widget;
using Training.Forms;
using Xamarin.Forms.Platform.Android;

[assembly: Xamarin.Forms.ExportRenderer(typeof(TaskListCell), typeof(Training.Android.TaskListCellRenderer))]

namespace Training.Android
{
    /// <summary>
    /// Custom renderer for the list cells on Android
    /// </summary>
    public class TaskListCellRenderer : ViewCellRenderer
    {

        #region Overrides

        protected override View GetCellCore(Xamarin.Forms.Cell item, View convertView, ViewGroup parent, Context context)
        {
            var x = (TaskListCell)item;
            var view = convertView;
            if(view == null) {
                view = (context as Activity).LayoutInflater.Inflate(Resource.Layout.TaskListCellAndroid, null);
            }

            view.FindViewById<TextView>(Resource.Id.name).Text = x.Name;
            view.FindViewById<TextView>(Resource.Id.incomplete_tasks).Text = x.IncompleteTasks;

            return view;
        }

        #endregion
    }
}

