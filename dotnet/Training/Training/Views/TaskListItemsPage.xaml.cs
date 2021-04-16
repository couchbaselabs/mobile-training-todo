using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Training.Models;
using Training.ViewModels;
using Training.Views;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace Training.Views
{
    public partial class TaskListItemsPage : ContentPage
    {
        TaskListItemsViewModel _viewModel;

        public TaskListItemsPage()
        {
            InitializeComponent();

            BindingContext = _viewModel = new TaskListItemsViewModel();
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            _viewModel.OnAppearing();
        }
    }
}