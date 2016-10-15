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
    /// Interaction logic for UsersView.xaml
    /// </summary>
    public partial class UsersView : BaseView
    {
        private UserCellModel _lastRightClicked;

        public UsersView()
        {
            InitializeComponent();
        }

        private void DeleteRow(object sender, RoutedEventArgs e)
        {
            _lastRightClicked.DeleteCommand.Execute(null);
        }

        private void ListViewItem_PreviewMouseRightButtonDown(object sender, MouseButtonEventArgs e)
        {
            var lvi = sender as ListViewItem;
            _lastRightClicked = lvi?.DataContext as UserCellModel;
        }
    }
}
