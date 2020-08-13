using Plugin.Media;
using Plugin.Media.Abstractions;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace Training.Core
{
    public class MediaService : IMediaService
    {
        public async Task<bool> IsCameraAvailable()
        {
            await CrossMedia.Current.Initialize();
            return CrossMedia.Current.IsCameraAvailable && CrossMedia.Current.IsTakePhotoSupported;
        }

        public async Task<byte[]> TakePhotoAsync()
        {
            var options = new StoreCameraMediaOptions
            {
                CompressionQuality = 100,
                // ADD OTHER OPTIONS HERE
            };

            var result = await CrossMedia.Current.TakePhotoAsync(options).ConfigureAwait(false);
            return result != null ? GetBytesFromStream(result.GetStream()) : null;
        }

        public async Task<byte[]> PickPhotoAsync()
        {
            var result = await CrossMedia.Current.PickPhotoAsync().ConfigureAwait(false);
            return result != null ? GetBytesFromStream(result.GetStream()) : null;
        }

        byte[] GetBytesFromStream(Stream stream)
        {
            using (var ms = new MemoryStream()) {
                stream.CopyTo(ms);
                return ms.ToArray();
            }
        }
    }
}
