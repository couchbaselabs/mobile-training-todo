using Training.ViewModels;
using Xamarin.Forms;

namespace Training.Views
{
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