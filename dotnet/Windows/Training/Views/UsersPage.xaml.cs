using Training.ViewModels;
using Xamarin.Forms;

namespace Training.Views
{
    public partial class UsersPage : ContentPage
    {
        UsersViewModel _viewModel;
        public UsersPage()
        {
            InitializeComponent();
            BindingContext = _viewModel = new UsersViewModel();
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            _viewModel.OnAppearing();
        }
    }
}
