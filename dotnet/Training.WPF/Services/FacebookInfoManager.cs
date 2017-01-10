//
//  FacebookTokenManager.cs
//
//  Author:
//  	Jim Borden  <jim.borden@couchbase.com>
//
//  Copyright (c) 2017 Couchbase, Inc All rights reserved.
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
using System.Configuration;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;

namespace Training.WPF.Services
{
    public static class FacebookInfoManager
    {
        private static Configuration _configuration = ConfigurationManager.OpenExeConfiguration(Assembly.GetExecutingAssembly().Location);

        public static string LoadAccessToken()
        {
            var encoded = _configuration.AppSettings.Settings["fb_token"].Value;
            if(String.IsNullOrEmpty(encoded)) {
                return encoded;
            }

            var bytes = Convert.FromBase64String(encoded);
            var decrypted = ProtectedData.Unprotect(bytes, null, DataProtectionScope.CurrentUser);
            return Encoding.ASCII.GetString(decrypted);
        }

        public static void SaveAccessToken(string token)
        {
            var secureToken = ProtectedData.Protect(Encoding.ASCII.GetBytes(token), null, DataProtectionScope.CurrentUser);
            _configuration.AppSettings.Settings["fb_token"].Value = Convert.ToBase64String(secureToken);
            _configuration.Save();

            ConfigurationManager.RefreshSection("appSettings");
        }

        public static string LoadId()
        {
            return _configuration.AppSettings.Settings["fb_userid"].Value;
        }

        public static void SaveId(string name)
        {
            _configuration.AppSettings.Settings["fb_userid"].Value = name;
            _configuration.Save();

            ConfigurationManager.RefreshSection("appSettings");
        }
    }
}
