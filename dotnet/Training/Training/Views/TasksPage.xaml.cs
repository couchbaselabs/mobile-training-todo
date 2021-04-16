using System.Linq;
using Xamarin.Forms;
using Training.Models;
using Training.ViewModels;

namespace Training.Views
{
    public partial class TasksPage : ContentPage
    {
        public TasksPage()
        {
            InitializeComponent();
        }

        async void OnCollectionViewSelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            string taskName = (e.CurrentSelection.FirstOrDefault() as TaskItem).Name;
            // The following route works because route names are unique in this application.
            await Shell.Current.GoToAsync($"taskdetails?name={taskName}");
            // The full route is shown below.
            // await Shell.Current.GoToAsync($"//animals/domestic/tasks/taskdetails?name={taskName}");
        }
    }
}
