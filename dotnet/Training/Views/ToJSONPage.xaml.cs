using Training.ViewModels;

namespace Training.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class ToJSONPage : ContentPage
    {
        public ToJSONPage()
        {
            InitializeComponent();
            BindingContext = new ToJSONViewModel();
        }
    }
}