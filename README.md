# ToDo Application
ToDo iOS sample app built with [CouchbaseLite 2.5.0](https://github.com/couchbase/couchbase-lite-ios/tree/release/iridium). 
The application has Android, DotNet, Objective-C and Swift versions.

## Requirements
- XCode 10.0


## How to build and run?
1. Clone the project and checkout `feature/2.5` branch.

 ```
 $ git clone https://github.com/couchbaselabs/mobile-training-todo.git
 $ git checkout feature/2.5
 ```
 
2. cd into the project: `android`, `dotnet`, `objc` or `swift`.

3. Download framework from [here](https://www.couchbase.com/downloads)(from mobile section) for the respective platform. 

4. Copy respective framework into the `Frameworks` folder. 
  - `CouchbaseLite.framework` for `objc` 
  - `CouchbaseLiteSwift.framework` for `swift`
 
5. Open project.
  - For iOS, open Todo.xcodeproj with your XCode. Select `Todo` scheme and Run. 

## How to use the replication feature?

1. [Download Sync Gateway](https://www.couchbase.com/downloads)(from mobile section). 
2. Start Sync Gateway with the configuration file in the root of this project.
=======
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
### iOS
1. From the AppDelegate in the XCode project, change kLoginFlowEnabled and kSyncEnabled variable to YES/true.
2. From the AppDelegate in the XCode project, change the hostname of the kSyncGatewayUrl as needed.
3. Rerun the Todo app.
