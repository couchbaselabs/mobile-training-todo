using System;
using System.Linq;
using Xamarin.Forms;
using Training.Data;
using Training.Models;

namespace Training.Views
{
    [QueryProperty(nameof(Name), "name")]
    public partial class TaskDetailPage : ContentPage
    {
        public string Name
        {
            set
            {
                LoadTask(value);
            }
        }

        public TaskDetailPage()
        {
            InitializeComponent();
        }

        void LoadTask(string name)
        {
            try
            {
                //TaskItem task = TasksData.Tasks.FirstOrDefault(a => a.Name == name);
                //BindingContext = task;
            }
            catch (Exception)
            {
                Console.WriteLine("Failed to load tassk.");
            }
        }
    }
}
