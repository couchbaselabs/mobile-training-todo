using Training.ViewModels;

namespace Training.Models
{
    public class TaskListItem : BaseViewModel
    {
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
    }
}