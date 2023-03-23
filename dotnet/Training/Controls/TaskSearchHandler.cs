using System;
using System.Linq;
using System.Threading.Tasks;
using Xamarin.Forms;
using Training.Models;
using Training.Services;
using Training.ViewModels;
using Training.Views;

namespace Training.Controls
{
    public class TaskSearchHandler : SearchHandler
    {
        private readonly IDataStore<TaskItem> _tasks = DependencyService.Get<IDataStore<TaskItem>>();

        protected override void OnQueryChanged(string oldValue, string newValue)
        {
            base.OnQueryChanged(oldValue, newValue);

            if (string.IsNullOrWhiteSpace(newValue))
            {
                ItemsSource = null;
            }
            else
            {
                ItemsSource = _tasks.Data.Values
                    .Where(task => task.Name.ToLower().Contains(newValue.ToLower()));
            }
        }

        protected override async void OnItemSelected(object item)
        {
            base.OnItemSelected(item);
            if(!(item is TaskItem task)) {
                return;
            }

            // Let the animation complete
            await Task.Delay(1000);
            await Shell.Current.GoToAsync($"{nameof(TaskDetailPage)}?{nameof(TaskDetailViewModel.TaskId)}={task.DocumentID}");
        }
    }
}
