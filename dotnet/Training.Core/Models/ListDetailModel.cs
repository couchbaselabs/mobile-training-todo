using Couchbase.Lite;
using Robo.Mvvm;
using System;
using System.Collections.Generic;
using System.Text;
using Training.Core;

namespace Training.Models
{
    public sealed class ListDetailModel : BaseNotify, IDisposable
    {
        #region Variables

        private Database _db;
        private Document _document;
        private string _username;

        /// <summary>
        /// Fired when a change in the database causes moderator status to be
        /// gained (enabling the users page to be visible)
        /// </summary>
        public event EventHandler ModeratorStatusGained;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the owner of the list being shown
        /// </summary>
        public string Owner => _document.GetString("owner");

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentId">The ID of the document containing the list details</param>
        public ListDetailModel(string documentId)
        {
            _db = CoreApp.Database;
            _document = _db.GetDocument(documentId);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Calculates whether or not the given user has moderator access to the 
        /// current list
        /// </summary>
        /// <returns><c>true</c>, if the user has access, <c>false</c> otherwise.</returns>
        /// <param name="username">The user to check access for.</param>
        public bool HasModerator(string username)
        {
            var moderatorDocId = $"moderator.{username}";
            var doc = _db.GetDocument(moderatorDocId);
            doc?.Dispose();
            return doc != null;
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            if (_username == null) {
                return;
            }

            // _db.Changed -= MonitorModeratorStatus;
        }

        #endregion
    }
}
