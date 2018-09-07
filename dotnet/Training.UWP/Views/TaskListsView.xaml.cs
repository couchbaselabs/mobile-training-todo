// The Blank Page item template is documented at https://go.microsoft.com/fwlink/?LinkId=234238

using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Training.Core;

namespace Training.UWP.Views
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class TaskListsView
    {
        public TaskListsView()
        {
            this.InitializeComponent();
        }

        private void EditRow(object sender, RoutedEventArgs e)
        {
            var source = e.OriginalSource;
        }

        private void OnItemClick(object sender, ItemClickEventArgs e)
        {
            var viewModel = DataContext as TaskListsViewModel;
            viewModel.SelectedItem = e.ClickedItem as TaskListCellModel;
        }
    }
}
