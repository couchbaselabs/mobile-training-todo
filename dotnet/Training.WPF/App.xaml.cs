using System;
using System.Windows;
using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;
using MvvmCross.Wpf.Views;
using Training.Core;
using Training.WPF.Services;
using XLabs.Platform.Device;

namespace Training.WPF
{
    public partial class App : Application
    {
        private bool _setupComplete;

        private void DoSetup()
        {
            LoadMvxAssemblyResources();

            var presenter = new WpfPresenter(MainWindow);

            var setup = new Setup(Dispatcher, presenter);
            setup.Initialize();

            UserDialogs.Instance = new UserDialogsImpl();
            Mvx.RegisterSingleton<IImageService>(() => new ImageService());
            Mvx.RegisterSingleton<IDevice>(new Device());

            var start = new CoreAppStart();
            var hint = CoreAppStart.CreateHint();
            start.Start(hint);

            _setupComplete = true;
        }

        protected override void OnActivated(EventArgs e)
        {
            if(!_setupComplete) {
                DoSetup();
            }

            base.OnActivated(e);
        }

        private void LoadMvxAssemblyResources()
        {
            for(var i = 0; ; i++) {
                var key = "MvxAssemblyImport" + i;
                var data = TryFindResource(key);
                if(data == null) {
                    return;
                }
            }
        }

        private void OnStartup(object sender, StartupEventArgs e)
        {
            if(e.Args.Length > 0 && e.Args[0].ToLowerInvariant() == "/clean") {
                CoreApp.AppWideManager.DeleteDatabase("todo");
            }
        }
    }
}