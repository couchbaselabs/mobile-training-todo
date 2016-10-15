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
using System.Windows.Input;

using MvvmCross.Core.ViewModels;
using Training.Core;

namespace Training
{
    /// <summary>
    /// A base for all view models in this application
    /// </summary>
    public abstract class BaseViewModel : MvxViewModel
    {

        #region Properties

        /// <summary>
        /// Gets the command for going back to a previous view model
        /// </summary>
        public ICommand BackCommand
        {
            get {
                return new MvxCommand(() => Close(this));
            }
        }

        #endregion
    }

    /// <summary>
    /// Another base view model that contains a property for its corresponding model
    /// </summary>
    public abstract class BaseViewModel<T> : BaseViewModel where T : BaseModel
    {

        #region Properties

        /// <summary>
        /// Gets (or sets in derived classes) the model that this view model
        /// will interact with
        /// </summary>
        public T Model { get; protected set; }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        protected BaseViewModel() 
        {
            
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="model">The model that this view model will interact with.</param>
        protected BaseViewModel(T model)
        {
            Model = model;
        }

        #endregion
    }
}

