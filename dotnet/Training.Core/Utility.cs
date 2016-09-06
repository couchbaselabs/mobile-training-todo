//
// JsonUtility.cs
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
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Acr.UserDialogs;
using MvvmCross.Platform;
using Newtonsoft.Json.Linq;
using XLabs.Platform.Services.Media;

namespace Training.Core
{
    /// <summary>
    /// A utility for getting rid of intermediate Newtonsoft classes when nested objects
    /// are deserialized from JSON
    /// </summary>
    public static class JsonUtility
    {
        public static IList<T> ConvertToNetList<T>(object jsonObject)
        {
            var arrayAttempt = ConvertToList<T>(jsonObject);
            if(arrayAttempt != null) {
                var retVal = new List<T>();
                foreach(var item in arrayAttempt) {
                    retVal.Add((T)ConvertToNetObject(item));
                }

                return retVal;
            }

            return null;
        }

        /// <summary>
        /// Converts the given object to a .NET object, ensuring that all contained objects
        /// are also .NET objects
        /// </summary>
        /// <returns>The converted object</returns>
        /// <param name="jsonObject">The object that potentially has Newtonsoft classes contained</param>
       public static object ConvertToNetObject(object jsonObject)
        {
            var dictionaryAttempt = ConvertToDictionary<string, object>(jsonObject);
            if(dictionaryAttempt != null) {
                var retVal = new Dictionary<string, object>();
                foreach(var pair in dictionaryAttempt) {
                    retVal[pair.Key] = ConvertToNetObject(pair.Value);
                }

                return retVal;
            }

            var arrayAttempt = ConvertToList<object>(jsonObject);
            if(arrayAttempt != null) {
                var retVal = new List<object>();
                foreach(var item in arrayAttempt) {
                    retVal.Add(ConvertToNetObject(item));
                }

                return retVal;
            }

            // If neither a list or dictionary, just return it as is
            return jsonObject;
        }

        /// <summary>
        /// The same as ConvertToNetObject, but strongly typed
        /// </summary>
        /// <returns>The converted object</returns>
        /// <param name="jsonObject">The object that potentially has Newtonsoft classes contained</param>
        /// <typeparam name="T">The type to return</typeparam>
        public static T ConvertToNetObject<T>(object jsonObject)
        {
            return (T)ConvertToNetObject(jsonObject);
        }

        private static IDictionary<K, V> ConvertToDictionary<K, V>(object obj)
        {
            var shortCut = obj as IDictionary<K, V>;
            if(shortCut != null) {
                return shortCut;
            }

            if(obj == null) {
                return null;
            }

            var jObj = obj as JObject;
            return jObj == null ? null : jObj.ToObject<IDictionary<K, V>>();
        }

        private static IList<T> ConvertToList<T>(object obj)
        {
            var shortCut = obj as IList<T>;
            if(shortCut != null) {
                return shortCut;
            }

            if(obj == null) {
                return null;
            }

            var jObj = obj as JArray;
            return jObj == null ? null : jObj.Select(x => x.ToObject<T>()).ToList();
        }
    }

    /// <summary>
    /// Convenience utility for extracting multiple pieces of information from a dictionary without
    /// throwing an exception
    /// </summary>
    public static class DictionaryUtility
    {
        /// <summary>
        /// Extracts the values for the given keys in the given dictionary to the given list
        /// </summary>
        /// <param name="source">The dictionary to check.</param>
        /// <param name="destination">The list to store the values in.</param>
        /// <param name="keys">The keys to extract.</param>
        public static bool Extract(this IDictionary<string, object> source, IList<object> destination, params string[] keys)
        {
            foreach(var key in keys) {
                if(!source.ContainsKey(key)) {
                    destination.Clear();
                    return false;
                }

                destination.Add(source[key]);
            }

            return true;
        }
    }

    public class ExtendedObservableCollection<T> : ObservableCollection<T>
    {
        public void Replace(IEnumerable<T> newItems)
        {
            var index = 0;
            foreach(T item in newItems) {
                if(index < Count) {
                    var existing = IndexOf(item);

                    if(existing == -1) {
                        SetItem(index, item);
                    } else if(existing != index) {
                        Move(existing, index);
                    }
                } else {
                    Add(item);
                }

                index++;
            }

            while(index < Count) {
                RemoveAt(index);
            }
        }
    }

    public sealed class ReactiveObservableCollection<T> : ExtendedObservableCollection<T> where T : INotifyPropertyChanged
    {
        
        protected override void OnCollectionChanged(NotifyCollectionChangedEventArgs e)
        {
            base.OnCollectionChanged(e);

            if(e.NewItems != null) {
                foreach(INotifyPropertyChanged item in e.NewItems) {
                    item.PropertyChanged += Item_PropertyChanged;
                }
            }

            if(e.OldItems != null) {
                foreach(INotifyPropertyChanged item in e.OldItems) {
                    item.PropertyChanged -= Item_PropertyChanged;
                }
            }
        }

        private void Item_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            Task.Run(() =>
            {
                var index = IndexOf((T)sender);
                if(index != -1) {
                    SetItem(index, (T)sender);
                }
            });
        }
    }

    public sealed class ImageChooser
    {
        private readonly ImageChooserConfig _config;

        public ImageChooser(ImageChooserConfig config) 
        {
            _config = config;
        }

        public async Task<Stream> GetPhotoAsync()
        {
            var result = default(string);
            if(_config.MediaPicker.IsCameraAvailable) {
                result = await _config.Dialogs.ActionSheetAsync(_config.Title, _config.CancelText, _config.DeleteText, CancellationToken.None, "Choose Existing", "Take Photo");
            } else {
                result = await _config.Dialogs.ActionSheetAsync(_config.Title, _config.CancelText, _config.DeleteText, CancellationToken.None, "Choose Existing");
            }

            if(result == _config.CancelText) {
                return null;
            }

            var photoResult = default(MediaFile);
            if(result == "Choose Existing") {
                try {
                    photoResult = await _config.MediaPicker.SelectPhotoAsync(new CameraMediaStorageOptions());
                } catch(OperationCanceledException) {
                    return null;
                }
            } else if(result == "Take Photo") {
                try {
                    photoResult = await _config.MediaPicker.TakePhotoAsync(new CameraMediaStorageOptions { DefaultCamera = CameraDevice.Rear, SaveMediaOnCapture = false });
                } catch(OperationCanceledException) {
                    return null;
                }
            } else if(result == _config.DeleteText) {
                return Stream.Null;
            }

            return photoResult?.Source;
        }
    }

    public sealed class ImageChooserConfig
    {
        public string Title { get; set; }

        public string DeleteText { get; set; }

        public string CancelText { get; set; } = "Cancel";

        public IUserDialogs Dialogs { get; set; } = Mvx.Resolve<IUserDialogs>();

        public IMediaPicker MediaPicker { get; set; } = Mvx.Resolve<IMediaPicker>();
    }
}

