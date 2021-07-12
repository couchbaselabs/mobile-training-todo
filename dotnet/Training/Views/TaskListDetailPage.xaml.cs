using Training.Models;
using Training.ViewModels;
using Xamarin.Forms;

namespace Training.Views
{
    public partial class TaskListDetailPage : ContentPage
    {
        public TaskListItem Item { get; set; }

        public TaskListDetailPage()
        {
            InitializeComponent();
            BindingContext = new TaskListDetailViewModel();
        }
    }
}