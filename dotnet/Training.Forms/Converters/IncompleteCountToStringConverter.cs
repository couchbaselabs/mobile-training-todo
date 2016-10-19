//
// IncompleteCountToStringConverter.cs
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
using System.Globalization;

using Xamarin.Forms;

namespace Training.Forms
{
    /// <summary>
    /// A converter to convert from an incomplete task count to a string (-1 is blank, and all others
    /// are simple string conversions)
    /// </summary>
    public sealed class IncompleteCountToStringConverter : IValueConverter
    {

        #region IValueConverter

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if(!(value is int)) {
                return String.Empty;
            }

            var val = (int)value;
            return val <= 0 ? String.Empty : val.ToString();
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var val = value as string;
            if(String.IsNullOrEmpty(val)) {
                return 0;
            }

            return Int32.Parse(val);
        }

        #endregion

    }
}

