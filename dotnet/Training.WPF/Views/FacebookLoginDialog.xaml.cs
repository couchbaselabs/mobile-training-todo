using System;
using System.Configuration;
using System.IO;
using System.Net;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Newtonsoft.Json;
using Training.WPF.Services;

namespace Training.WPF.Views
{
    public sealed class FacebookLoginCompleteEventArgs : EventArgs
    {
        [Flags]
        public enum LoginResult
        {
            Success,
            Failure,
            Cancellation
        }

        public LoginResult Result { get; }

        internal FacebookLoginCompleteEventArgs(LoginResult loginResult)
        {
            Result = loginResult;
        }
    }

    /// <summary>
    /// Interaction logic for FacebookLoginDialog.xaml
    /// </summary>
    public partial class FacebookLoginDialog : Window
    {
        private bool _finishedProcess;

        public event EventHandler<FacebookLoginCompleteEventArgs> LoginCompleted;

        public FacebookLoginDialog()
        {
            InitializeComponent();

            Closing += (sender, args) =>
            {
                if(!_finishedProcess) {
                    LoginCompleted?.Invoke(this, new FacebookLoginCompleteEventArgs(FacebookLoginCompleteEventArgs.LoginResult.Cancellation));
                }
            };
        }

        

        private void WebBrowser_Navigating(object sender, NavigatingCancelEventArgs e)
        {
            if(e.Uri.Host == "www.facebook.com" && e.Uri.LocalPath == "/connect/login_success.html") {
                _finishedProcess = true;
                StoreToken(e.Uri.Fragment);
                StoreUserId();

                e.Cancel = true;
                Close();
            }
        }

        private void WebBrowser_Loaded(object sender, RoutedEventArgs e)
        {
            ((WebBrowser)sender).Navigate("https://www.facebook.com/v2.8/dialog/oauth?auth_type=rerequest&client_id=510926975701287&response_type=token&&redirect_uri=https%3A%2F%2Fwww.facebook.com%2Fconnect%2Flogin_success.html&scope=email");
        }

        private void StoreToken(string urlFragment)
        {
            var match = Regex.Match(urlFragment, "#access_token=([^&]*)&?");
            if(match == null) {
                return;
            }

            var accessToken = match.Groups[1].Value;
            FacebookInfoManager.SaveAccessToken(accessToken);
        }

        private async void StoreUserId()
        {
            var uri = new Uri("https://graph.facebook.com/me");
            var request = WebRequest.CreateHttp(uri);
            request.Headers["Authorization"] = $"OAuth {FacebookInfoManager.LoadAccessToken()}";
            var response = await request.GetResponseAsync();
            var responseStream = response.GetResponseStream();
            var deserializer = new JsonSerializer();
            using(var reader = new JsonTextReader(new StreamReader(responseStream))) {
                dynamic responseBody = deserializer.Deserialize(reader);
                var id = responseBody.id;
                FacebookInfoManager.SaveId(Convert.ToString(id));
            }

            LoginCompleted?.Invoke(this, new FacebookLoginCompleteEventArgs(FacebookLoginCompleteEventArgs.LoginResult.Success));
        }
    }
}
