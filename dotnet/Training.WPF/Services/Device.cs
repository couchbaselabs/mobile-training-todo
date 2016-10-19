//
//  Device.cs
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
using System.Threading.Tasks;

using XLabs.Enums;
using XLabs.Platform.Device;
using XLabs.Platform.Services;
using XLabs.Platform.Services.IO;
using XLabs.Platform.Services.Media;

namespace Training.WPF.Services
{
    // An implementation of the IDevice interface for WPF 
    // (mostly unimplemented, except what is needed for this app)
    internal sealed class Device : IDevice
    {
        public IAccelerometer Accelerometer
        {
            get {
                throw new NotImplementedException();
            }
        }

        public IBattery Battery
        {
            get {
                throw new NotImplementedException();
            }
        }

        public IBluetoothHub BluetoothHub
        {
            get {
                throw new NotImplementedException();
            }
        }

        public IDisplay Display
        {
            get {
                throw new NotImplementedException();
            }
        }

        public IFileManager FileManager
        {
            get {
                throw new NotImplementedException();
            }
        }

        public string FirmwareVersion
        {
            get {
                throw new NotImplementedException();
            }
        }

        public IGyroscope Gyroscope
        {
            get {
                throw new NotImplementedException();
            }
        }

        public string HardwareVersion
        {
            get {
                throw new NotImplementedException();
            }
        }

        public string Id
        {
            get {
                throw new NotImplementedException();
            }
        }

        public string LanguageCode
        {
            get {
                throw new NotImplementedException();
            }
        }

        public string Manufacturer
        {
            get {
                throw new NotImplementedException();
            }
        }

        public IMediaPicker MediaPicker
        {
            get {
                return new MediaPicker();
            }
        }

        public IAudioStream Microphone
        {
            get {
                throw new NotImplementedException();
            }
        }

        public string Name
        {
            get {
                return "WPF Shell";
            }
        }

        public INetwork Network
        {
            get {
                throw new NotImplementedException();
            }
        }

        public Orientation Orientation
        {
            get {
                throw new NotImplementedException();
            }
        }

        public IPhoneService PhoneService
        {
            get {
                throw new NotImplementedException();
            }
        }

        public string TimeZone
        {
            get {
                throw new NotImplementedException();
            }
        }

        public double TimeZoneOffset
        {
            get {
                throw new NotImplementedException();
            }
        }

        public long TotalMemory
        {
            get {
                throw new NotImplementedException();
            }
        }

        public Task<bool> LaunchUriAsync(Uri uri)
        {
            throw new NotImplementedException();
        }
    }
}
