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
using System.Collections.Generic;
using System.Linq;

using Newtonsoft.Json.Linq;

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
}

