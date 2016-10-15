using System;
using System.ComponentModel;
using System.Windows;
using System.Windows.Input;
using MvvmCross.Core.ViewModels;
using MvvmCross.Wpf.Views;
using Training.Core;

namespace Training
{
    /// <summary>
    /// Interaction logic for ListDetailView.xaml
    /// </summary>
    public partial class ListDetailView : BaseView
    {
        private bool _initialized;

        public ICommand AddCommand
        {
            get {
                return new MvxCommand(() =>
                {
                    if(_tasksView.IsVisible) {
                        (_tasksView.DataContext as TasksViewModel).AddCommand.Execute(null);
                    } else {
                        (_usersView.DataContext as UsersViewModel).AddCommand.Execute(null);
                    }
                });
            }
        }

        public ListDetailView()
        {
            InitializeComponent();

            DataContextChanged += OnDataContextChanged;
        }

        private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            var viewModel = DataContext as ListDetailViewModel;
            if(viewModel == null || _initialized) {
                return;
            }

            _tasksView.DataContext = _tasksView.ViewModel = new TasksViewModel(viewModel);
            _usersView.DataContext = _usersView.ViewModel = new UsersViewModel(viewModel);

            if(!viewModel.HasModeratorStatus) {
                viewModel.PropertyChanged += EnableUsersView;
            } else {
                _viewMenu.Visibility = Visibility.Visible;
            }

            _initialized = true;
        }

        private void EnableUsersView(object sender, PropertyChangedEventArgs e)
        {
            var viewModel = DataContext as ListDetailViewModel;
            if(viewModel == null) {
                return;
            }

            if(e.PropertyName == nameof(viewModel.HasModeratorStatus)) {
                if(viewModel.HasModeratorStatus) {
                    _viewMenu.Visibility = Visibility.Visible;
                }
            }
        }

        private void UpdateView(object sender, RoutedEventArgs e)
        {
            if(_usersMenuItem == null) {
                return;
            }

            if(e.Source == _tasksMenuItem) {
                if(!_tasksMenuItem.IsChecked) {
                    return;
                }

                _usersMenuItem.IsChecked = false;
                _tasksView.Visibility = Visibility.Visible;
                _usersView.Visibility = Visibility.Collapsed;
            } else {
                if(!_usersMenuItem.IsChecked) {
                    return;
                }

                _tasksMenuItem.IsChecked = false;
                _usersView.Visibility = Visibility.Visible;
                _tasksView.Visibility = Visibility.Collapsed;
            }
        }

        protected override void Dispose(bool finalizing)
        {
            base.Dispose(finalizing);

            _usersView.Dispose();
            _tasksView.Dispose();
        }
    }
}
