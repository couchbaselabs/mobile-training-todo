using Training.ViewModels;
using Xamarin.Forms;

namespace Training.Views
{
    public partial class TaskListItemPage : Shell
    {
        public TaskListItemPage()
        {
            InitializeComponent();
            BindingContext = new TaskListItemViewModel();
        }
    }
}