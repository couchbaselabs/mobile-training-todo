// 
// UsersView.xaml.cs
// 
// Author:
//     Sandy Chuang  <sandy.chuang@couchbase.com>
// 
// Copyright (c) 2018 Couchbase, Inc All rights reserved.
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
using Training.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

// The Blank Page item template is documented at https://go.microsoft.com/fwlink/?LinkId=234238

namespace Training.UWP.Views
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class UsersView
    {
        public UsersView()
        {
            this.InitializeComponent();
        }

        private void DeleteRow(object sender, RoutedEventArgs e)
        {
            var data = ((FrameworkElement)sender).DataContext as UserCellModel;
            data.StatusUpdated += UpdateView;
        }

        private void UpdateView()
        {
            var viewModel = DataContext as UsersViewModel;
            viewModel.Model.Filter(null);
        }
    }
}
