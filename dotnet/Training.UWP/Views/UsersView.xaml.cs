using Training.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

// The Blank Page item template is documented at https://go.microsoft.com/fwlink/?LinkId=234238

namespace Training.UWP.Views
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class UsersView
    {
        public UsersView()
        {
            this.InitializeComponent();
        }

        private void OnItemClick(object sender, ItemClickEventArgs e)
        {
            var viewModel = DataContext as UsersViewModel;
            viewModel.SelectedItem = e.ClickedItem as UserCellModel;
        }

        private void DeleteRow(object sender, RoutedEventArgs e)
        {

        }
    }
}
