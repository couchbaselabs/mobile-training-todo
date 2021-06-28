using System;
using System.Globalization;
using System.IO;
using Xamarin.Forms;

namespace Training.Utils
{
    /// <summary>
    /// A converter to convert a byte array into an ImageSource for Xamarin Forms
    /// </summary>
    public class ByteArrayToImageConverter : IValueConverter
    {
        #region IValueConverter

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            ImageSource retSource = null;

            try
            {
                if (value != null)
                {
                    retSource = ImageSource.FromStream(() => new MemoryStream((byte[])value));
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ByteToImageFieldConverter Exception: {ex.Message}");
            }

            return retSource ?? null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotSupportedException();
        }

        #endregion
    }
}
