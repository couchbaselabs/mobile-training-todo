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
        /// Gets the command that gets fired when a search is requested
        /// </summary>
        public ICommand SearchCommand
        {
            get {
                return new MvxCommand(() => Console.WriteLine("Foo"));
            }
        }

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
        public TasksViewModel(ListDetailViewModel parent) : base(new TasksModel(parent.Username, parent.CurrentTaskID))
        {
            _dialogs = Mvx.Resolve<IUserDialogs>();
            ListData.CollectionChanged += (sender, e) => 
            {
                if(e.NewItems == null) {
                    return;
                }

                foreach(TaskCellModel item in e.NewItems) {
                    item.AddImageCommand = new MvxAsyncCommand(() => ShowOrChooseImage(item));
                }
            };
        }

        internal async Task ShowOrChooseImage(TaskCellModel taskDocument)
        {
            if(taskDocument.Thumbnail == null) {
                await ChooseImage(taskDocument);
            } else {
                ShowViewModel<TaskImageViewModel>(new { databaseName = Model.DatabaseName, documentID = taskDocument.Document.Id });
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

