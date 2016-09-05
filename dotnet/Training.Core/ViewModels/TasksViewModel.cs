//
// TasksViewModel.cs
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
using System.Collections.ObjectModel;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;
using XLabs.Platform.Services.Media;

namespace Training.Core
{
    /// <summary>
    /// The view model for the list of tasks page
    /// </summary>
    public class TasksViewModel : BaseViewModel<TasksModel>
    {
        private readonly IUserDialogs _dialogs;

        public TaskCellModel SelectedItem
        {
            get {
                return _selectedItem;
            }
            set {
                if(_selectedItem == value) {
                    return;
                }

                _selectedItem = value;
                value.IsChecked = !value.IsChecked;
                SetProperty(ref _selectedItem, null);
            }
        }
        private TaskCellModel _selectedItem;

        /// <summary>
        /// Gets the list of tasks for display in the list view
        /// </summary>
        /// <value>The list data.</value>
        public ObservableCollection<TaskCellModel> ListData
        {
            get {
                return Model.ListData;
            }
        }

        /// <summary>
        /// Gets or sets the current text being searched for in the list
        /// </summary>
        public string SearchTerm
        {
            get {
                return _searchTerm;
            }
            set {
                if(SetProperty(ref _searchTerm, value)) {
                    Model.Filter(value);
                }
            }
        }
        private string _searchTerm;

        /// <summary>
        /// Gets the command that is fired when the add button is pressed
        /// </summary>
        /// <value>The add command.</value>
        public ICommand AddCommand
        {
            get {
                return new MvxCommand(AddNewItem);
            }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="parent">The parent view model (this is a nested view model).</param>
        public TasksViewModel(ListDetailViewModel parent) : base(new TasksModel(parent.Username, parent.CurrentListID))
        {
            _dialogs = Mvx.Resolve<IUserDialogs>();
            ListData.CollectionChanged += (sender, e) => 
            {
                if(e.NewItems == null) {
                    return;
                }

                foreach(TaskCellModel item in e.NewItems) {
                    if(item.AddImageCommand == null) {
                        item.AddImageCommand = new MvxAsyncCommand(() => ShowOrChooseImage(item));
                    }
                }
            };
        }

        internal async Task ShowOrChooseImage(TaskCellModel taskDocument)
        {
            if(taskDocument.Thumbnail == null || taskDocument.Thumbnail == Stream.Null) {
                await ChooseImage(taskDocument);
            } else {
                ShowViewModel<TaskImageViewModel>(new { databaseName = Model.DatabaseName, documentID = taskDocument.DocumentID });
            }
        }

        private async Task ChooseImage(TaskCellModel taskDocument)
        {
            var mediaPicker = Mvx.Resolve<IMediaPicker>();
            var result = default(string);
            if(mediaPicker.IsCameraAvailable) {
                result = await _dialogs.ActionSheetAsync(null, "Cancel", "Delete", CancellationToken.None, "Choose Existing", "Take Photo");
            } else {
                result = await _dialogs.ActionSheetAsync(null, "Cancel", "Delete", CancellationToken.None, "Choose Existing");
            }

            if(result == "Cancel") {
                return;
            }

            var photoResult = default(MediaFile);
            if(result == "Choose Existing") {
                try {
                    photoResult = await mediaPicker.SelectPhotoAsync(new CameraMediaStorageOptions());
                } catch(OperationCanceledException) {
                    return;
                }
            } else if(result == "Take Photo") {
                try {
                    photoResult = await mediaPicker.TakePhotoAsync(new CameraMediaStorageOptions { DefaultCamera = CameraDevice.Rear, SaveMediaOnCapture = false });
                } catch(OperationCanceledException) {
                    return;
                }
            }

            await taskDocument.SetImage(photoResult.Source);
        }

                
        private void AddNewItem()
        {
            _dialogs.Prompt(new PromptConfig {
                OnAction = CreateNewItem,
                Title = "New Task",
                Placeholder = "Task Name"
            });
        }

        private void CreateNewItem(PromptResult result)
        {
            if(!result.Ok) {
                return;
            }

            try {
                Model.CreateNewTask(result.Text);
            } catch(Exception e) {
                _dialogs.ShowError(e.Message);
            }
        }
    }
}

