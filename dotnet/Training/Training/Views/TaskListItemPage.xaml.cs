using Training.ViewModels;
using Xamarin.Forms;

namespace Training.Views
{
    public partial class TaskListItemPage : Shell
    {
        TaskListItemViewModel _viewModel;
        public TaskListItemPage()
        {
            InitializeComponent();
            BindingContext = _viewModel = new TaskListItemViewModel();
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();
            _viewModel.OnDisappearing();
        }
    }
}