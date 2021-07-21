using Training.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace Training.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class UsersPage : ContentPage
    {
        UsersViewModel _viewModel;
        public UsersPage()
        {
            InitializeComponent();
            BindingContext = _viewModel = new UsersViewModel();
        }

        //protected override void OnAppearing()
        //{
        //    base.OnAppearing();
        //    _viewModel.OnAppearing();
        //}
    }
}
