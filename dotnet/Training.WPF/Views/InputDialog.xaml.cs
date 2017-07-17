//
//  InputDialog.xaml.cs
//
//  Author:
//  	Jim Borden  <jim.borden@couchbase.com>
//
//  Copyright (c) 2016 Couchbase, Inc All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

using System;
using System.Windows;
using System.Windows.Controls;

namespace Training.WPF.Views
{
    /// <summary>
    /// A dialog for prompting the user for some text
    /// </summary>
    public partial class InputDialog : Window, IDisposable
    {

        #region Properties

        /// <summary>
        /// Gets or sets the text that was entered by the user
        /// </summary>
        public string Text
        {
            get {
                return IsPassword ? _passwordBox.Password : _inputBox.Text;
            }
            set {
                if(IsPassword) {
                    _passwordBox.Password = value;
                } else {
                    _inputBox.Text = value;
                }
            }
        }

        /// <summary>
        /// Gets or sets the text for the confirmation button
        /// </summary>
        public string OkText
        {
            get {
                return _okButton.Content as string;
            }
            set {
                _okButton.Content = value;
            }
        }

        /// <summary>
        /// Gets or sets the text for the cancellation button
        /// </summary>
        public string CancelText
        {
            get {
                return _cancelButton.Content as string;
            }
            set {
                _cancelButton.Content = value;
            }
        }

        /// <summary>
        /// Gets or sets whether or not the input should be masked from the user
        /// </summary>
        public bool IsPassword
        {
            get {
                return _passwordBox.Visibility == Visibility.Visible;
            }
            set {
                _passwordBox.Visibility = value ? Visibility.Visible : Visibility.Collapsed;
                _inputBox.Visibility = value ? Visibility.Collapsed : Visibility.Visible;
            }
        }

        /// <summary>
        /// Gets whether or not the OK button was pressed
        /// </summary>
        public bool WasOk
        {
            get; private set;
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        public InputDialog()
        {
            InitializeComponent();
        }

        #endregion

        #region Private API

        private void HandleButtonClick(object sender, RoutedEventArgs e)
        {
            e.Handled = true;
            WasOk = !((Button)sender).IsCancel;
            Close();
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            // No-op, needed for IUserDialogs
        }

        #endregion

    }
}
