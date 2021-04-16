using System;
using System.Collections.Generic;
using System.ComponentModel;
using Training.Models;
using Training.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace Training.Views
{
    public partial class NewTaskListItemPage : ContentPage
    {
        public TaskListItem Item { get; set; }

        public NewTaskListItemPage()
        {
            InitializeComponent();
            BindingContext = new NewTaskListItemViewModel();
        }
    }
}