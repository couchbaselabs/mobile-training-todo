using Training.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

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