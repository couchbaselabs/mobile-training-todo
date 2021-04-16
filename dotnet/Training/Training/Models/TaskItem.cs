using System;
using System.Collections.Generic;
using System.Text;

namespace Training.Models
{
    public class TaskItem
    {
        /// <summary>
        /// Gets the ID of the document being tracked
        /// </summary>
        /// <value>The document identifier.</value>
        public string DocumentID { get; set; }

        /// <summary>
        /// Gets the name of the task
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets whether or not this document is "checked off" (i.e. finished)
        /// </summary>
        /// <value><c>true</c> if the entry is checked off; otherwise, <c>false</c>.</value>
        public bool IsChecked { get; set; }

        /// <summary>
        /// Gets the thumbnail of the image stored with the task, if it exists
        /// </summary>
        public byte[] Thumbnail { get; set; }
    }
}
