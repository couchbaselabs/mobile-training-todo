using System;
using System.Windows;
using System.Windows.Controls;

using Acr.UserDialogs;

namespace Training.WPF.Views
{
    /// <summary>
    /// Interaction logic for InputDialog.xaml
    /// </summary>
    public partial class InputDialog : Window, IDisposable
    {
        public string Text
        {
            get {
                return IsPassword ? _passwordBox.Password : _inputBox.Text;
            }
            set {
                if(IsPassword) {
                    _passwordBox.Password = value;
                } else {
                    _inputBox.Text = value;
                }
            }
        }

        public string OkText
        {
            get {
                return _okButton.Content as string;
            }
            set {
                _okButton.Content = value;
            }
        }

        public string CancelText
        {
            get {
                return _cancelButton.Content as string;
            }
            set {
                _cancelButton.Content = value;
            }
        }

        public bool IsPassword
        {
            get {
                return _passwordBox.Visibility == Visibility.Visible;
            }
            set {
                _passwordBox.Visibility = value ? Visibility.Visible : Visibility.Collapsed;
                _inputBox.Visibility = value ? Visibility.Collapsed : Visibility.Visible;
            }
        }

        public bool WasOk
        {
            get; private set;
        }

        public InputDialog()
        {
            InitializeComponent();

            
        }

        private void HandleButtonClick(object sender, RoutedEventArgs e)
        {
            e.Handled = true;
            WasOk = !((Button)sender).IsCancel;
            Close();
        }

        public void Dispose()
        {
            // No-op
        }
    }
}
