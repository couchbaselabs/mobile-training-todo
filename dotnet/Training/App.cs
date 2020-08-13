using CouchbaseLabs.MVVM;
using CouchbaseLabs.MVVM.Services;

using Training.Core;
using Training.ViewModels;
using Training.Views;

using Xamarin.Forms;


namespace Training
{
    public partial class App : Application // superclass new in 1.3
    {
        INavigationService NavigationService { get; set; }

        public App()
        {
            var startup = new CoreAppStart();
            var hint = CoreAppStart.CreateHint();

            RegisterServices();
            if (hint.LoginEnabled) {

                NavigationService.ReplaceRoot(ServiceContainer.GetInstance<LoginViewModel>(), false);
            } else {
                NavigationService.ReplaceRoot(ServiceContainer.GetInstance<TaskListsViewModel>(), false);
            }
        }

        void RegisterServices()
        {
            //ServiceContainer.Register<IAlertService>(new AlertService());
            //ServiceContainer.Register<IMediaService>(new MediaService());

            NavigationService = new NavigationService();
            NavigationService.AutoRegister(typeof(App).Assembly);

            ServiceContainer.Register(NavigationService);
        }
    }
}
