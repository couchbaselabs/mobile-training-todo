## .NET Training

### Architecture

This training application is built on the principles of Model-View-View Model (MVVM) and might be a little overwhelming to look at, but most of it is application specific and you don't need to concern yourself too much with it.  However, here is a brief high level look at the architecture:

- View
 - The only responsibility at this level is displaying things on the screen.  This part is the most platform specific out of the layers and need to be rewritten for each deployment platform.  Because of this, as little logic as possible should be included in this layer.  The mobile platforms will be handled using Xamarin.Forms, which helps a lot with abstracting the UI into a powerful variant of XML called XAML.  Through the use of *Data Binding*, we can dynamically set a certain class to control the parameters of what is displayed.  This type of class is called:
- View Model
 - This class is the logic of the view, basically.  It reacts to certain inputs, and changes its state to the appropriate output and sends out events of the changes that occurred.  The view will then react to these changes and update its display.  Because there is no view specific code in here, the view model does not (and should not) know anything about the view that displays its information.  That means that this level is platform independent as it just deals in standard C# types.  
- Model
 - This level deals with the storing and retrieving of data from a certain backend.  All Couchbase Lite operations will take place at this level.  It is useful to contain the logic here so that it is easy to simply write another model to get data from another source, and have the view model read from that instead without changing anything in the view model.  Note that like the view model, the model knows nothing about the view model that uses it, or the view above that.  It too simply takes parameters, and retrieves the information requested of it.

### Other Concepts Used

#### Services

Sometimes platform specific logic cannot be avoided, and there are two ways to deal with this.  You could clutter up the class with a lot if `#if` directives, or you could use injection.  The framework used in this application has an *Inversion of Control* container (IoC) built into it.  This type of container allows an app to work based on interfaces, with the actual implementation registered and consumed at runtime.  In fact, Xamarin.Forms is one big IoC container if you think about it.  It simply handles all the work transparently (i.e. using the appropriate class to display images despite it never being specified in the app code).  However, not all the types or logic that we need come prebaked and so having an IoC container is very powerful.  This is used, among other things, to generate thumbnails and show the camera / media picker.

#### IValueConverter

This interface allows the conversion of any type of object to another and it is useful because often times the UI framework for a platform requires types that are specific to the platform.  If you put these types directly into the view model you break platform independence, and so instead you can assign an `IValueConverter` implementation to the property which will convert the property received from the view model to the appropriate type for the UI framework.

### Organization

- Training.Android: The platform specific code for Android
- Training.Core: The view model and model layer, as well as interfaces for services
 - Models: The models, where all the Couchbase Lite functionality lives
 - Services: Service interface definitions
 - ViewModels: The view models
- Training.Forms: The view layer for Xamarin Forms, and any applicable `IValueConverter`
 - Converters: `IValueConverter` definitions
 - Views: UI for Xamarin Forms
- Training.iOS: The platform specific code for iOS
- Training.WPF: The view layer for WPF, any applicable `IValueConverter`, and WPF platform specific code

### Frameworks Used

- [Couchbase Lite .NET](https://github.com/couchbase/couchbase-ite-net)
 - For reasons which I hope are obvious
- [MvvmCross](https://github.com/MvvmCross/MvvmCross)
 - This framework allows application of MVVM in a cross platform way
- [Xamarin Forms](https://www.xamarin.com/forms)
 - Allows an abstract UI to be written for iOS, Android, and Windows Phone
- [XLabs Platform](https://github.com/XLabs/Xamarin-Forms-Labs)
 - Adds on to the functionality of Xamarin Forms
- [ACR User Dialogs](https://github.com/aritchie/userdialogs)
 - A framework for easily creating dialogs, popups, etc in a cross platform manner