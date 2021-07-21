using Training.Models;
using Training.ViewModels;
using Xamarin.Forms;

namespace Training.Views
{
    public partial class TaskListDetailPage : ContentPage
    {
        public TaskListDetailPage()
        {
            InitializeComponent();
            BindingContext = new TaskListDetailViewModel();
        }
    }
}