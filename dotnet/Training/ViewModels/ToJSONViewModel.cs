using System.Windows.Input;

namespace Training.ViewModels
{
    [QueryProperty(nameof(JSONString), nameof(JSONString))]
    public class ToJSONViewModel : BaseViewModel
    {
        private string _jsonString;
        public string JSONString
        {
            get => _jsonString;
            set => SetProperty(ref _jsonString, value);
        }

        public ICommand BackCommand => new Command(async () =>
        {
            await Shell.Current.GoToAsync("..");
        });
    }
}
