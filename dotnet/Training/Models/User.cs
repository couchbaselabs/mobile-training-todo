using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace Training.Models
{
    public class User : INotifyPropertyChanged
    {
        private string _docId;
        private string _name;
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
        /// Gets the name of the user
        /// </summary>
        public string Name
        {
            get { return _name; }
            set { SetProperty(ref _name, value); }
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
