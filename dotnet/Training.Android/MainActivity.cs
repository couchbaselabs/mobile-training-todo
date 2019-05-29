using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Acr.UserDialogs;
using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.OS;
using Android.Runtime;
using Android.Views;
using Android.Widget;
using Prototype.Mvvm;
using Training.Core;
using XLabs.Platform.Device;
using XLabs.Platform.Services.Media;

namespace Training.Android
{
    [Activity(MainLauncher = true, Label = "Todo", ScreenOrientation = ScreenOrientation.Portrait, Icon = "@android:color/transparent", Theme = "@style/MyTheme", ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation)]
    public class MainActivity : global::Xamarin.Forms.Platform.Android.FormsAppCompatActivity
    {
        protected override void OnCreate(Bundle bundle)
        {
            //TabLayoutResource = Resource.Layout.SplashScreen; 
            //ToolbarResource = Resource.Layout.TaskListCellAndroid;

            base.OnCreate(bundle);

            // tag::activate[]
            Couchbase.Lite.Support.Droid.Activate(ApplicationContext);
            // end::activate[]

            global::Xamarin.Forms.Forms.Init(this, bundle);
            UserDialogs.Init(this);
            Plugin.CurrentActivity.CrossCurrentActivity.Current.Init(this, bundle);

            RegisterServices();

            LoadApplication(new App());
        }

        void RegisterServices()
        {
            ServiceContainer.Register<IDevice>(AndroidDevice.CurrentDevice);
            ServiceContainer.Register<IImageService>(new ImageService());
            //ServiceContainer.Register<IMediaPicker>(new MediaPicker());
            //ServiceContainer.Register<IDatabaseSeedService>(() => new DatabaseSeedService(ApplicationContext));
        }
    }
}