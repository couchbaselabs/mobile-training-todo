using MvvmCross.Core.ViewModels;
using MvvmCross.Forms.Views;
using MvvmCross.Forms.Platform;
using MvvmCross.iOS.Platform;
using MvvmCross.iOS.Views.Presenters;
using MvvmCross.Platform.Platform;
using Training.Core;
using UIKit;
using MvvmCross.Forms.iOS;
using Training.Forms;
using MvvmCross.iOS.Views;
using MvvmCross.Core.Views;
using System.Reflection;
using MvvmCross.Platform.IoC;
using System.Linq;
using System;

namespace Training.iOS
{
    /// <summary>
    /// This class contains instructions on how to set up the application (platform specific)
    /// </summary>
    public sealed class Setup : MvxFormsIosSetup
    {
        public Setup(IMvxApplicationDelegate applicationDelegate, UIWindow window)
            : base(applicationDelegate, window)
        {
        }

        protected override IMvxApplication CreateApp()
        {
            return new CoreApp();
        }
  
        protected override IMvxTrace CreateDebugTrace()
        {
            return new DebugTrace();
        }

        protected override MvxFormsApplication CreateFormsApplication()
        {
            return new App();
        }

        protected override IMvxIosViewsContainer CreateIosViewsContainer()
        {
            var viewsContainer = base.CreateIosViewsContainer();
            var viewModelTypes =
                typeof(LoginViewModel).GetTypeInfo().Assembly.CreatableTypes().Where(t => t.Name.EndsWith("ViewModel")).ToDictionary(t => t.Name.Remove(t.Name.LastIndexOf("ViewModel", StringComparison.Ordinal)));
            var viewTypes =
                typeof(LoginPage).GetTypeInfo().Assembly.CreatableTypes().Where(t => t.Name.EndsWith("Page")).ToDictionary(t => t.Name.Remove(t.Name.LastIndexOf("Page", StringComparison.Ordinal)));
            foreach (var viewModelTypeAndName in viewModelTypes)
            {
                Type viewType;
                if (viewTypes.TryGetValue(viewModelTypeAndName.Key, out viewType))
                    viewsContainer.Add(viewModelTypeAndName.Value, viewType);
            }

            return viewsContainer;
        }
    }
}
