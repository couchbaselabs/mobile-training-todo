using Training.Models;
using Training.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace Training.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class TaskListItemsPage : ContentPage
    {
        TaskListItemsViewModel _viewModel;

        public TaskListItemsPage()
        {
            InitializeComponent();
            BindingContext = _viewModel = new TaskListItemsViewModel();
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            _viewModel.OnAppearing();
        }
    }
}