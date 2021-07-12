using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xamarin.Forms;
using Training.Models;
using Training.Views;
using System.Collections.ObjectModel;

namespace Training.Controls
{
    public class TaskSearchHandler : SearchHandler
    {
        public ObservableCollection<TaskItem> Tasks { get; set; }
        public Type SelectedItemNavigationTarget { get; set; }

        protected override void OnQueryChanged(string oldValue, string newValue)
        {
            base.OnQueryChanged(oldValue, newValue);

            if (string.IsNullOrWhiteSpace(newValue))
            {
                ItemsSource = null;
            }
            else
            {
                ItemsSource = Tasks
                    .Where(task => task.Name.ToLower().Contains(newValue.ToLower()))
                    .ToList<TaskItem>();
            }
        }

        protected override async void OnItemSelected(object item)
        {
            base.OnItemSelected(item);

            // Let the animation complete
            await Task.Delay(1000);

            ShellNavigationState state = (App.Current.MainPage as Shell).CurrentState;
            // The following route works because route names are unique in this application.
            await Shell.Current.GoToAsync($"{GetNavigationTarget()}?name={((TaskItem)item).Name}");
        }

        string GetNavigationTarget()
        {
            return (Shell.Current as AppShell).Routes.FirstOrDefault(route => route.Value.Equals(SelectedItemNavigationTarget)).Key;
        }
    }
}
