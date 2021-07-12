using Xamarin.Forms;
using Training.ViewModels;

namespace Training.Views
{
    public partial class UserDetailPage : ContentPage
    {
        public UserDetailPage()
        {
            InitializeComponent();
            BindingContext = new UserDetailViewModel();
        }
    }
}
