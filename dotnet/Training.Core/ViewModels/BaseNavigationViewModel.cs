using System.Threading.Tasks;
using Acr.UserDialogs;
using Robo.Mvvm;
using Robo.Mvvm.Services;
using Robo.Mvvm.ViewModels;
using Training.Models;

namespace Training.ViewModels
{
    public abstract class BaseNavigationViewModel : BaseViewModel
    {
        protected INavigationService Navigation { get; set; }

        protected IUserDialogs Dialogs { get; set; }

        protected BaseNavigationViewModel(INavigationService navigationService)
        {
            Navigation = navigationService;
        }

        protected BaseNavigationViewModel(INavigationService navigationService, IUserDialogs dialogs)
        {
            Navigation = navigationService;
            Dialogs = dialogs;
        }

        public Task Dismiss() => Navigation.PopAsync();
    }

    /// <summary>
    /// Another base view model that contains a property for its corresponding model
    /// </summary>
    public abstract class BaseNavigationViewModel<T> : BaseNavigationViewModel where T : BaseNotify
    {
        #region Properties

        /// <summary>
        /// Gets (or sets in derived classes) the model that this view model
        /// will interact with
        /// </summary>
        public T Model { get; protected set; }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        protected BaseNavigationViewModel(INavigationService navigation) : base(navigation)
        {
        }

        protected BaseNavigationViewModel(INavigationService navigation, IUserDialogs dialogs)
            : base(navigation, dialogs)
        {
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="model">The model that this view model will interact with.</param>
        protected BaseNavigationViewModel(INavigationService navigation, T model) : base(navigation)
        {
            Model = model;
        }

        protected BaseNavigationViewModel(INavigationService navigation, IUserDialogs dialogs, T model) : base(navigation, dialogs)
        {
            Model = model;
        }

        #endregion
    }

    public abstract class BaseCollectionViewModel<T> : BaseCollectionViewModel where T : BaseNotify
    {
        #region Properties

        /// <summary>
        /// Gets (or sets in derived classes) the model that this view model
        /// will interact with
        /// </summary>
        public T Model { get; protected set; }

        #endregion
    }
}
