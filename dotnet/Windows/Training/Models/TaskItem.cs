using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace Training.Models
{
    public class TaskItem : INotifyPropertyChanged
    {
        private string _docId;
        private string _name;
        private bool _isChecked;
        private byte[] _image;

        public string TaskListID { get; set; }

        /// <summary>
        /// Gets the ID of the document being tracked
        /// </summary>
        /// <value>The document identifier.</value>
        public string DocumentID
        {
            get { return _docId; }
            set { SetProperty(ref _docId, value); }
        }

        /// <summary>
        /// Gets the name of the task
        /// </summary>
        public string Name
        {
            get { return _name; }
            set { SetProperty(ref _name, value); }
        }

        /// <summary>
        /// Gets or sets whether or not this document is "checked off" (i.e. finished)
        /// </summary>
        /// <value><c>true</c> if the entry is checked off; otherwise, <c>false</c>.</value>
        public bool IsChecked
        {
            get { return _isChecked; }
            set 
            { 
                if(SetProperty(ref _isChecked, value))
                {
                    using(var doc = CoreApp.Database.GetDocument(_docId))
                    using(var mdoc =  doc.ToMutable())
                    {
                        mdoc.SetBoolean("complete", value);
                        CoreApp.Database.Save(mdoc);
                    }
                }
            }
        }

        /// <summary>
        /// Gets the thumbnail of the image stored with the task, if it exists
        /// </summary>
        public byte[] Thumbnail
        {
            get { return _image; }
            set { SetProperty(ref _image, value); }
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
