//
//  TaskListsView.xaml.cs
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

using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

using Training.Core;

namespace Training
{
    /// <summary>
    /// The view that displays a list of tasks lists from a given database
    /// </summary>
    public partial class TaskListsView : BaseView
    {

        #region Variables

        // To get around the fact that a context menu exists on the list itself and not
        // the list item
        private TaskListCellModel _lastRightClicked;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        public TaskListsView()
        {
            InitializeComponent();

            DataContextChanged += (sender, args) =>
            {
                var vm = DataContext as TaskListsViewModel;
                if(_actionMenu.Items.Count == 1 && vm?.LoginEnabled == true) {
                    var logoutItem = new MenuItem {
                        Header = "Logout...",
                        Command = vm.LogoutCommand
                    };
                    _actionMenu.Items.Add(logoutItem);
                }
            };
        }

        #endregion

        #region Private API

        private void DeleteRow(object sender, RoutedEventArgs e)
        {
            _lastRightClicked.DeleteCommand.Execute(null);
        }

        private void EditRow(object sender, RoutedEventArgs e)
        {
            _lastRightClicked.EditCommand.Execute(null);
        }

        private void ListViewItem_PreviewMouseRightButtonDown(object sender, MouseButtonEventArgs e)
        {
            var lvi = sender as ListViewItem;
            _lastRightClicked = lvi?.DataContext as TaskListCellModel;
        }

        private void ListViewItem_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            var lvi = sender as ListViewItem;
            var viewModel = DataContext as TaskListsViewModel;
            viewModel.SelectedItem = lvi.DataContext as TaskListCellModel;
        }

        #endregion

    }
}
