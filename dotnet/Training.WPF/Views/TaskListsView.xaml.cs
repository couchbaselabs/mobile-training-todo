using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using MvvmCross.Wpf.Views;
using Training.Core;

namespace Training
{
    /// <summary>
    /// Interaction logic for TaskListsView.xaml
    /// </summary>
    public partial class TaskListsView : MvxWpfView
    {
        private TaskListCellModel _lastRightClicked;

        public TaskListsView()
        {
            InitializeComponent();

            DataContextChanged += (sender, args) =>
            {
                var vm = DataContext as TaskListsViewModel;
                if(_actionMenu.Items.Count == 1 && vm?.LoginEnabled == true) {
                    var logoutItem = new MenuItem {
                        Header = "Logout...",
                        Command = vm.LogoutCommand
                    };
                    _actionMenu.Items.Add(logoutItem);
                }
            };
        }

        private void DeleteRow(object sender, RoutedEventArgs e)
        {
            _lastRightClicked.DeleteCommand.Execute(null);
        }

        private void EditRow(object sender, RoutedEventArgs e)
        {
            _lastRightClicked.EditCommand.Execute(null);
        }

        private void ListViewItem_PreviewMouseRightButtonDown(object sender, MouseButtonEventArgs e)
        {
            var lvi = sender as ListViewItem;
            _lastRightClicked = lvi?.DataContext as TaskListCellModel;
        }

        private void ListViewItem_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            var lvi = sender as ListViewItem;
            var viewModel = DataContext as TaskListsViewModel;
            viewModel.SelectedItem = lvi.DataContext as TaskListCellModel;
        }
    }
}
