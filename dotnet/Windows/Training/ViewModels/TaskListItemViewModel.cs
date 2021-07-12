using System.Collections.ObjectModel;
using Training.Models;
using Xamarin.Forms;

namespace Training.ViewModels
{
    [QueryProperty(nameof(ListItemId), nameof(ListItemId))]
    class TaskListItemViewModel : BaseViewModel
    {
        public string ListItemId { get; set; }

        public void OnDisappearing()
        {

        }
    }
}
