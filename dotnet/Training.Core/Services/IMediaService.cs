using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace Training.Core
{
    public interface IMediaService
    {
        Task<bool> IsCameraAvailable();
        Task<byte[]> TakePhotoAsync();
        Task<byte[]> PickPhotoAsync();
    }
}
