//
//  MainWindow.xaml.cs
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
using System.Windows.Input;

using XLabs;

namespace Training.WPF
{
    /// <summary>
    /// The main window for the app
    /// </summary>
    public partial class MainWindow : Window
    {

        #region Properties

        public ICommand CreateConflictCommand
        {
            get {
                //HACK: MvxCommand is not available at this point because IoC is not prepared yet
                return new RelayCommand(() =>
                {
                    var listsPage = Content as TaskListsView;
                    if(listsPage != null) {
                        var vm = listsPage?.DataContext as TaskListsViewModel;
                        vm?.TestConflict();
                    } else {
                        var tasksPage = Content as ListDetailView;
                        tasksPage?.TestConflict();
                    }
                });
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        public MainWindow()
        {
            InitializeComponent();
        }

        #endregion

    }
}
