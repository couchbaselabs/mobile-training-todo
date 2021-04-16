using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace Training.Models
{
    public class TaskListItem
    {
        /// <summary>
        /// Gets the document ID of the document being tracked
        /// </summary>
        public string DocumentID { get; set; }

        /// <summary>
        /// Gets or sets the incomplete count for this row
        /// </summary>
        public int IncompleteCount { get; set; }

        /// <summary>
        /// Gets or sets the name of the list
        /// </summary>
        public string Name { get; set; }
        
        public ObservableCollection<TaskItem> Tasks { get; set; }
        public ObservableCollection<User> Users { get; set; }

        public TaskListItem()
        {
            Tasks = new ObservableCollection<TaskItem>();
            Users = new ObservableCollection<User>();
        }

    }
}