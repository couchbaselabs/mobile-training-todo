using Acr.UserDialogs;

using Prototype.Mvvm;
using Prototype.Mvvm.Services;

using Training.Core;
using Training.Core.Services;
using Training.Services;
using Training.ViewModels;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace Training
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
	public partial class App : Application
    {
        INavigationService NavigationService { get; set; }

        public App()
        {
            InitializeComponent();

            RegisterServices();

            var start = new CoreAppStart();
            var hint = CoreAppStart.CreateHint();
            start.Start(hint);

            if (hint.LoginEnabled) {
                NavigationService.SetDetailAsync(ServiceContainer.GetInstance<LoginViewModel>(), false);
            } else {
                NavigationService.SetDetailAsync(ServiceContainer.GetInstance<TaskListsViewModel>(), false);
        }
    }

        void RegisterServices()
        {
            ServiceContainer.Register(UserDialogs.Instance);
            ServiceContainer.Register<IMediaService>(new MediaService());

            NavigationService = new NavigationService();
            NavigationService.AutoRegister(typeof(App).Assembly);

            ServiceContainer.Register(NavigationService);
        }
    }
}