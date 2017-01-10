//
//  LoginView.xaml.cs
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
using System.Net;
using System.Windows;

using MvvmCross.Wpf.Views;
using Training.Core;
using Training.WPF.Services;
using Training.WPF.Views;

namespace Training
{
    /// <summary>
    /// The view that handles user login
    /// </summary>
    public partial class LoginView : MvxWpfView
    {

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        public LoginView()
        {
            InitializeComponent();
        }

        #endregion

        #region Private API

        private void OnLoginClick(object sender, RoutedEventArgs e)
        {
            // _passBox.Password is not bindable for security reasons
            // This method is not terribly secure and a better one should probably be
            // thought of
            (ViewModel as LoginViewModel).LoginCommand.Execute(_passBox.Password);
        }

        private async void OnFacebookLoginClick(object sender, RoutedEventArgs e)
        {
            var savedToken = FacebookInfoManager.LoadAccessToken();
            if(String.IsNullOrEmpty(savedToken)) {
                PerformLoginSteps();
            } else {
                var check = WebRequest.CreateHttp("https://graph.facebook.com/me");
                check.Headers["Authorization"] = $"OAuth {FacebookInfoManager.LoadAccessToken()}";
                var response = (HttpWebResponse)await check.GetResponseAsync();
                if(response.StatusCode == HttpStatusCode.Unauthorized) {
                    PerformLoginSteps();
                } else if(response.StatusCode == HttpStatusCode.OK) {
                    CompleteLogin();
                }
            }
        }

        private void PerformLoginSteps()
        {
            var fb = new FacebookLoginDialog();
            fb.LoginCompleted += (fbSender, fbArgs) =>
            {
                if(fbArgs.Result == FacebookLoginCompleteEventArgs.LoginResult.Success) {
                    CompleteLogin();
                }
            };
            fb.ShowDialog();
        }

        private void CompleteLogin()
        {
            var savedToken = FacebookInfoManager.LoadAccessToken();
            (ViewModel as LoginViewModel).Username = $"fb_{FacebookInfoManager.LoadId()}";
            (ViewModel as LoginViewModel).FacebookLoginCommand.Execute(savedToken);
        }

        #endregion
    }
}
