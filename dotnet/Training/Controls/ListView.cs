using System;
using System.Collections.Generic;
using System.Text;
using System.Windows.Input;
using Xamarin.Forms;

namespace Training.Controls
{
    public class ListView : Xamarin.Forms.ListView
    {
        public static readonly BindableProperty ItemTappedCommandProperty =
            BindableProperty.Create(nameof(ItemTappedCommand), typeof(ICommand), typeof(ListView));

        public ICommand ItemTappedCommand
        {
            get { return (ICommand)GetValue(ItemTappedCommandProperty); }
            set { SetValue(ItemTappedCommandProperty, value); }
        }

        public ListView()
        {
            ItemTapped += OnItemTapped;
        }

        public ListView(ListViewCachingStrategy strategy) : base(Device.RuntimePlatform.Equals("iOS")
                                                                 ? ListViewCachingStrategy.RetainElement : strategy)
        {
            ItemTapped += OnItemTapped;
        }

        void OnItemTapped(object sender, ItemTappedEventArgs e)
        {
            if (e.Item != null && ItemTappedCommand != null && ItemTappedCommand.CanExecute(e)) {
                ItemTappedCommand.Execute(e.Item);
                SelectedItem = null;
            }
        }
    }
}
