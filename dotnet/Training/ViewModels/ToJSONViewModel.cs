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
