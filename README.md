# ToDo Application
ToDo iOS sample app built with [CouchbaseLite 2.0 Developer Preview](https://github.com/couchbase/couchbase-lite-ios/tree/feature/2.0). 
The application has both Objective-C and Swift version.

## Requirements
- XCode 8.3

## How to build and run?
1. Clone the project and checkout `feature/2.0` branch.

 ```
 $ git clone https://github.com/couchbaselabs/mobile-training-todo.git
 $ git checkout feature/2.0
 ```
 
2. cd into the project either `objc` or `swift`.

3. Download `CouchbaseLite.framework` or `CouchbaseLiteSwift.framework` from [here](https://developer.couchbase.com/documentation/mobile/2.0/whatsnew.html?language=ios).

4. Copy `CouchbaseLite.framework` for `objc` or `CouchbaseLiteSwift.framework` for `swift` into the `Frameworks` folder.
 
5. Open Todo.xcodeproj with your XCode.

6. Select `Todo` scheme and Run.

## How to use the replication feature?

1. [Download Sync Gateway 1.5 beta](https://developer.couchbase.com/documentation/mobile/2.0/whatsnew.html?language=ios)
2. Start Sync Gateway with the configuration file in the root of this project.

 ```
~/Downloads/couchbase-sync-gateway/bin/sync_gateway sync-gateway-config.json
 ```
3. From the AppDelegate in the XCode project, change kLoginFlowEnabled and kSyncEnabled variable to YES/true.
4. From the AppDelegate in the XCode project, change the hostname of the kSyncGatewayUrl as needed.
5. Rerun the Todo app.

## How to use the Facebook Login?
### Setup the Facebook App 
1. Go to Facebook Developers Page [link](https://developers.facebook.com/apps). 
2. Add a new App.
3. Provide a Display Name & a contact email address.
4. Now  Set Up the Facebook Login
5. Note the App-ID, which we will be using in our apps info.plist.

### Configure the Xcode project
1. Open the Xcode project and open the info.plist as Source code.
2. Look for the section with the comment _Update the Facebook App Details Below_ 
3. Update the value for _CFBundleURLSchemes_ with _fb<APP_ID>_
4. Update the value for _FacebookAppID_ with _<APP_ID>_ 
