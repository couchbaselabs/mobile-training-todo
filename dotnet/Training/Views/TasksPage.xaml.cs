﻿using Xamarin.Forms;
using Training.ViewModels;
using Xamarin.Forms.Xaml;

namespace Training.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class TasksPage : ContentPage
    {
        TasksViewModel _viewModel;
        public TasksPage()
        {
            InitializeComponent();

            BindingContext = _viewModel = new TasksViewModel();
        }

        //protected override void OnAppearing()
        //{
        //    base.OnAppearing();
        //    _viewModel.OnAppearing();
        //}
    }
}
