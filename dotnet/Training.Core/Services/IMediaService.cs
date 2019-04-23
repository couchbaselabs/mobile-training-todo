using System.Threading.Tasks;

namespace Training.Core.Services
{
    public interface IMediaService
    {
        Task<byte[]> PickPhotoAsync();
    }
}
