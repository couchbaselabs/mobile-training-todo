﻿using Training.ViewModels;

namespace Training.Views
{
    public partial class TaskListDetailPage : ContentPage
    {
        public TaskListDetailPage()
        {
            InitializeComponent();
            BindingContext = new TaskListDetailViewModel();
        }
    }
}