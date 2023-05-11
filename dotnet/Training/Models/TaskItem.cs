using Training.ViewModels;
using Training.Data;

namespace Training.Models
{
    public class TaskItem : BaseViewModel
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
                if (_isChecked != value)
                {
                    SetProperty(ref _isChecked, value);
                    var collection = CoreApp.Database.GetCollection(TasksData.TaskCollection);
                    using (var doc = collection.GetDocument(DocumentID))
                    {
                        if (doc.GetBoolean("complete") != _isChecked)
                        {
                            using (var mdoc = doc.ToMutable())
                            {
                                mdoc.SetBoolean("complete", _isChecked);
                                collection.Save(mdoc);
                            }
                        }
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

        public override string ToString()
        {
            return Name;
        }
    }
}
