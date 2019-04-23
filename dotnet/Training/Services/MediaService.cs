using Plugin.Media;

using System.IO;
using System.Threading.Tasks;

using Training.Core.Services;

namespace Training.Services
{
    public class MediaService : IMediaService
    {
        public async Task<byte[]> PickPhotoAsync()
        {
            var result = await CrossMedia.Current.PickPhotoAsync();
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
