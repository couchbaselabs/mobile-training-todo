# ToDo Application
ToDo sample app. 

## How to build and run?
1. Clone the project.

 ```
 $ git clone https://github.com/couchbaselabs/mobile-training-todo.git
 ```
2. Go into the folder based on your platform selection.

3. For the iOS platform (objc or swift), download the latest [Couchbase Lite](https://www.couchbase.com/downloads) for Objectve-C or Swift. Copy `CouchbaseLite.framework` for Objective-C or `CouchbaseLiteSwift.framework` for Swift into the `Frameworks` folder.

4. Depending on your selected platform, use an appropriate IDE (XCode for iOS, Android Studio for Android, and Xamarin Studio for .NET) to open the ToDo application project.

5. Run the application.

## How to use the replication feature?

1. Download the latest [Sync Gateway](https://www.couchbase.com/downloads).
2. Start Sync Gateway with the the configuration from [here](https://github.com/couchbaselabs/mobile-training-todo/blob/master/objc/sync-gateway-config.json) as follows:

 ```
~/Downloads/couchbase-sync-gateway/bin/sync_gateway sync-gateway-config.json
 ```
3. Depending on your selected platform, enable Login and Sync feature from the source code (e.g. `AppDelegate.m` for Objective-C, `AppDelegate.swift` for Swift or `Application.java` for Android). Then change the `hostname` variable in the same source code to point to your sync-gateway URL.

4. Rerun the application.
