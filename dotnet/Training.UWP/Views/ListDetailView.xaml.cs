// 
// ListDetailView.xaml.cs
// 
// Author:
//     Jim Borden  <jim.borden@couchbase.com>
// 
// Copyright (c) 2017 Couchbase, Inc All rights reserved.
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
using System.Windows.Input;
using Windows.UI.Xaml;
using MvvmCross.Core.ViewModels;
using Training.Core;

// The Blank Page item template is documented at https://go.microsoft.com/fwlink/?LinkId=234238

namespace Training.UWP.Views
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class ListDetailView
    {
        #region Variables

        public static DependencyProperty ToggleButtonVisibilityProperty = DependencyProperty.Register(
            "ToggleButtonVisibilty", typeof(Visibility),
            typeof(ListDetailView), new PropertyMetadata(Visibility.Collapsed));

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
                    //if (_tasksView.Visibility == Visibility.Visible) {
                        (_tasksView.DataContext as TasksViewModel).AddCommand.Execute(null);
                    //} else {
                    //    (_usersView.DataContext as UsersViewModel).AddCommand.Execute(null);
                    //}
                });
            }
        }

        public Visibility ToggleButtonVisibility
        {
            get => (Visibility) GetValue(ToggleButtonVisibilityProperty);
            set => SetValue(ToggleButtonVisibilityProperty, value);
        }

        #endregion

        #region Constructors

        public ListDetailView()
        {
            this.InitializeComponent();

            DataContextChanged += OnDataContextChanged;
        }

        #endregion

        #region Private Methods

        private void OnDataContextChanged(FrameworkElement sender, DataContextChangedEventArgs args)
        {
            var viewModel = DataContext as ListDetailViewModel;
            if (viewModel == null || _initialized) {
                return;
            }

            _initialized = true;
            _tasksView.ViewModel = new TasksViewModel(viewModel);
            //_usersView.DataContext = _usersView.ViewModel = new UsersViewModel(viewModel);

            //if (!viewModel.HasModeratorStatus) {
            //    viewModel.PropertyChanged += EnableUsersView;
            //} else {
            //    _viewMenu.Visibility = Visibility.Visible;
            //}

            
        }

        private void UpdateView(object sender, RoutedEventArgs e)
        {

        }

        #endregion
    }
}
