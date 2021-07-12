using System;
using System.Collections.Generic;
using System.Text;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(JSONString), nameof(JSONString))]
    public class ToJSONViewModel:BaseViewModel
    {
        private string _jsonString;
        public string JSONString
        {
            get => _jsonString;
            set => SetProperty(ref _jsonString, value);
        }
    }
}
