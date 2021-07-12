using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace Training.Models
{
    public class TaskListItem : INotifyPropertyChanged
    {
        private string _docId;
        private int _incompleteCnt;
        private string _name;

        /// <summary>
        /// Gets the document ID of the document being tracked
        /// </summary>
        public string DocumentID { get; set; }

        /// <summary>
        /// Gets or sets the incomplete count for this row
        /// </summary>
        public int IncompleteCount
        {
            get { return _incompleteCnt; }
            set { SetProperty(ref _incompleteCnt, value); }
        }

        /// <summary>
        /// Gets or sets the name of the list
        /// </summary>
        public string Name
        {
            get { return _name; }
            set { SetProperty(ref _name, value); }
        }

        //public ObservableCollection<TaskItem> Tasks { get; set; }
        //public ObservableCollection<User> Users { get; set; }

        public TaskListItem()
        {
            //Tasks = new ObservableCollection<TaskItem>();
            //Users = new ObservableCollection<User>();
        }

        protected bool SetProperty<T>(ref T backingStore, T value,
            [CallerMemberName] string propertyName = "",
            Action onChanged = null)
        {
            if (EqualityComparer<T>.Default.Equals(backingStore, value))
                return false;

            backingStore = value;
            onChanged?.Invoke();
            OnPropertyChanged(propertyName);
            return true;
        }

        #region INotifyPropertyChanged
        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged([CallerMemberName] string propertyName = "")
        {
            var changed = PropertyChanged;
            if (changed == null)
                return;

            changed.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
        #endregion
    }
}