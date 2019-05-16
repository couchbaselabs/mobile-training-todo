using System;
using System.IO;
using System.Threading.Tasks;
using Windows.Media.Capture;
using Windows.Storage.Pickers;
using Microsoft.Win32;
using XLabs.Platform.Services.Media;

namespace Training.UWP.Services
{
    // An implementation of IMediaPicker for WPF, using OpenFileDialog
    internal sealed class MediaPicker : IMediaPicker
    {

        #region Properties

        public bool IsCameraAvailable
        {
            get => true;
        }

        public bool IsPhotosSupported
        {
            get => true;
        }

        public bool IsVideosSupported
        {
            get => false;
        }

        public EventHandler<MediaPickerErrorArgs> OnError { get; set; }

        public EventHandler<MediaPickerArgs> OnMediaSelected { get; set; }

        #endregion

        #region IMediaPicker

        public async Task<MediaFile> SelectPhotoAsync(CameraMediaStorageOptions options)
        {
            var picker = new FileOpenPicker();
            picker.ViewMode = PickerViewMode.Thumbnail;
            picker.SuggestedStartLocation = PickerLocationId.PicturesLibrary;
            picker.FileTypeFilter.Add(".png");
            picker.FileTypeFilter.Add(".jpg");
            picker.FileTypeFilter.Add(".jpeg");

            var file = await picker.PickSingleFileAsync();
            if (file != null) {
                return new MediaFile(file.Name, () => file.OpenStreamForReadAsync().Result);
            }

            return null;
        }

        public Task<MediaFile> SelectVideoAsync(VideoMediaStorageOptions options)
        {
            throw new NotImplementedException();
        }

        public async Task<MediaFile> TakePhotoAsync(CameraMediaStorageOptions options)
        {
            var captureUI = new CameraCaptureUI();
            captureUI.PhotoSettings.Format = CameraCaptureUIPhotoFormat.Png;
            var photo = await captureUI.CaptureFileAsync(CameraCaptureUIMode.Photo);
            if (photo == null) {
                return null;
            }

            return new MediaFile(photo.Name, () => photo.OpenStreamForReadAsync().Result);
        }

        public Task<MediaFile> TakeVideoAsync(VideoMediaStorageOptions options)
        {
            throw new NotImplementedException();
        }

        #endregion

    }
}
