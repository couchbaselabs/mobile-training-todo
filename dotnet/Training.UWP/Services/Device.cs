using System;
using System.Threading.Tasks;

using XLabs.Enums;
using XLabs.Platform.Device;
using XLabs.Platform.Services;
using XLabs.Platform.Services.IO;
using XLabs.Platform.Services.Media;

namespace Training.UWP.Services
{
    // An implementation of the IDevice interface for UWP 
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
                return "UWP Shell";
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
