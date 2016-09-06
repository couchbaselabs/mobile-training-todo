//
// BaseViewModel.cs
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
using MvvmCross.Core.ViewModels;
using Training.Core;

namespace Training
{
    /// <summary>
    /// A base for all view models in this application
    /// </summary>
    public abstract class BaseViewModel : MvxViewModel
    {
        // Reserved for future expansion
    }

    /// <summary>
    /// Another base view model that contains a property for its corresponding model
    /// </summary>
    public abstract class BaseViewModel<T> : BaseViewModel where T : BaseModel
    {
        public T Model { get; protected set; }

        protected BaseViewModel() 
        {
            
        }

        protected BaseViewModel(T model)
        {
            Model = model;
        }
    }
}

