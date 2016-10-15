using System.Windows.Threading;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;
using MvvmCross.Platform.Platform;
using MvvmCross.Wpf.Platform;
using MvvmCross.Wpf.Views;
using Training.Core;
using Training.WPF.Services;
using XLabs.Platform.Device;

namespace Training.WPF
{
    public class Setup
        : MvxWpfSetup
    {
        public Setup(Dispatcher dispatcher, IMvxWpfViewPresenter presenter)
            : base(dispatcher, presenter)
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
    }
}
