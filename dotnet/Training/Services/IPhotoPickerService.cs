using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace Training.Services
{
    public interface IPhotoPickerService
    {
        Task<Stream> GetImageStreamAsync();
    }
}
