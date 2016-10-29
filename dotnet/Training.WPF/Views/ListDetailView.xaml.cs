//
//  ListDetailView.xaml.cs
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

using System.ComponentModel;
using System.Windows;
using System.Windows.Input;

using MvvmCross.Core.ViewModels;
using Training.Core;

namespace Training
{
    /// <summary>
    /// Interaction logic for ListDetailView.xaml
    /// </summary>
    public partial class ListDetailView : BaseView
    {

        #region Variables

        private bool _initialized;

        #endregion

        #region Properties

        /// <summary>
        /// The command that handles the logic for adding an item to the
        /// currently visible list
        /// </summary>
        public ICommand AddCommand
        {
            get {
                return new MvxCommand(() =>
                {
                    if(_tasksView.IsVisible) {
                        (_tasksView.DataContext as TasksViewModel).AddCommand.Execute(null);
                    } else {
                        (_usersView.DataContext as UsersViewModel).AddCommand.Execute(null);
                    }
                });
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        public ListDetailView()
        {
            InitializeComponent();

            DataContextChanged += OnDataContextChanged;
        }

        #endregion

        #region Internal API

        internal void TestConflict()
        {
            if(_tasksView.IsVisible) {
                (_tasksView.DataContext as TasksViewModel).TestConflict();
            }
        }

        #endregion

        #region Private API

        private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            var viewModel = DataContext as ListDetailViewModel;
            if(viewModel == null || _initialized) {
                return;
            }

            _tasksView.DataContext = _tasksView.ViewModel = new TasksViewModel(viewModel);
            _usersView.DataContext = _usersView.ViewModel = new UsersViewModel(viewModel);

            if(!viewModel.HasModeratorStatus) {
                viewModel.PropertyChanged += EnableUsersView;
            } else {
                _viewMenu.Visibility = Visibility.Visible;
            }

            _initialized = true;
        }

        private void EnableUsersView(object sender, PropertyChangedEventArgs e)
        {
            var viewModel = DataContext as ListDetailViewModel;
            if(viewModel == null) {
                return;
            }

            if(e.PropertyName == nameof(viewModel.HasModeratorStatus)) {
                if(viewModel.HasModeratorStatus) {
                    _viewMenu.Visibility = Visibility.Visible;
                }
            }
        }

        private void UpdateView(object sender, RoutedEventArgs e)
        {
            if(_usersMenuItem == null) {
                return;
            }

            if(e.Source == _tasksMenuItem) {
                if(!_tasksMenuItem.IsChecked) {
                    return;
                }

                _usersMenuItem.IsChecked = false;
                _tasksView.Visibility = Visibility.Visible;
                _usersView.Visibility = Visibility.Collapsed;
            } else {
                if(!_usersMenuItem.IsChecked) {
                    return;
                }

                _tasksMenuItem.IsChecked = false;
                _usersView.Visibility = Visibility.Visible;
                _tasksView.Visibility = Visibility.Collapsed;
            }
        }

        #endregion

        #region Overrides

        protected override void Dispose(bool finalizing)
        {
            base.Dispose(finalizing);

            _usersView.Dispose();
            _tasksView.Dispose();
        }

        #endregion

    }
}
