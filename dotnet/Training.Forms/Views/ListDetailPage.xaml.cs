//
// ListDetailPage.xaml.cs
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
using System;
using System.Collections.Generic;
using MvvmCross.Core.ViewModels;
using MvvmCross.Forms.Presenter.Core;
using MvvmCross.Platform;
using Training.Core;
using Xamarin.Forms;

namespace Training
{
    public partial class ListDetailPage : TabbedPage
    {
        public ListDetailPage()
        {
            InitializeComponent();
        }

        protected override void OnBindingContextChanged()
        {
            base.OnBindingContextChanged();

            var viewModel = BindingContext as ListDetailViewModel;
            if(viewModel == null) {
                return;
            }

            var child1 = (TasksPage)Children[0];
            child1.BindingContext = new TasksViewModel(viewModel);

            var child2 = (UsersPage)Children[1];
            child2.BindingContext = new UsersViewModel(viewModel);
        }
    }
}

