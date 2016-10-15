using System.Windows;
using MvvmCross.Wpf.Views;
using Training.Core;

namespace Training
{
    /// <summary>
    /// Interaction logic for LoginView.xaml
    /// </summary>
    public partial class LoginView : MvxWpfView
    {
        public LoginView()
        {
            InitializeComponent();
        }

        private void OnLoginClick(object sender, RoutedEventArgs e)
        {
            (ViewModel as LoginViewModel).LoginCommand.Execute(_passBox.Password);
        }
    }
}
