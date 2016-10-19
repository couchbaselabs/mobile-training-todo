﻿//
// TaskListCellModel.cs
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
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;

namespace Training.Core
{
    /// <summary>
    /// The view model for an entry in the TaskListsPage table view
    /// </summary>
    public sealed class TaskListCellModel : BaseViewModel<TaskListModel>
    {

        #region Variables

        private IUserDialogs _dialogs = Mvx.Resolve<IUserDialogs>();

        #endregion

        #region Properties

        /// <summary>
        /// Gets the document ID of the document being tracked
        /// </summary>
        public string DocumentID { get; }

        /// <summary>
        /// Gets the handler for an edit request
        /// </summary>
        public ICommand EditCommand
        {
            get {
                return new MvxAsyncCommand(Edit);
            }
        }

        /// <summary>
        /// Gets the handler for a delete request
        /// </summary>
        public ICommand DeleteCommand
        {
            get {
                return new MvxCommand(Delete);
            }
        }

        /// <summary>
        /// Gets or sets the incomplete count for this row
        /// </summary>
        public int IncompleteCount 
        {
            get {
                return _incompleteCount;
            }
            set {
                SetProperty(ref _incompleteCount, value);
            }
        }
        private int _incompleteCount;

        /// <summary>
        /// Gets the name of the list
        /// </summary>
        public string Name 
        {
            get {
                return Model.Name;
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentId">The ID of the document to track.</param>
        public TaskListCellModel(string documentId) 
            : base(new TaskListModel(documentId))
        {
            DocumentID = documentId;
            _incompleteCount = -1;
        }

        #endregion

        #region Private API

        private void Delete()
        {
            try {
                Model.Delete();
            } catch(Exception e) {
                _dialogs.ShowError(e.Message);
            }
        }

        private async Task Edit()
        {
            var result = await _dialogs.PromptAsync(new PromptConfig {
                Title = "Edit Task List",
                Text = Name,
                Placeholder = "List Name"
            });

            if(result.Ok) {
                try {
                    Model.Edit(result.Text);
                } catch(Exception e) {
                    _dialogs.ShowError(e.Message);
                }
            }
        }

        #endregion

        #region Overrides

        public override bool Equals(object obj)
        {
            var other = obj as TaskListCellModel;
            if(other == null) {
                return false;
            }

            return DocumentID.Equals(other.DocumentID) && Name.Equals(other.Name) && IncompleteCount == other.IncompleteCount;
        }

        public override int GetHashCode()
        {
            return DocumentID.GetHashCode() ^ (Name ?? "").GetHashCode() ^ IncompleteCount.GetHashCode();
        }

        #endregion

    }
}

