## Getting Started

```bash
git clone https://github.com/couchbaselabs/mobile-training-todo.git
cd mobile-training-todo/react-native
npm install && react-native start
```

1. Open **react-native/ios/ReactNativeCouchbaseLiteExample.xcodeproj** in Xcode or **react-native/android** in Android Studio.
2. Build and run. You should see an empty screen, use the red button to add a list.

	<img width="25%" src="https://cloud.githubusercontent.com/assets/2589337/21619898/abefd0cc-d1e9-11e6-8e8a-5bb2d39f0911.png" />

3. Open **app/DataManager.js** and set the following flags to `true`.

	```bash
	global.LOGIN_FLOW_ENABLED = true;
	const SYNC_ENABLED = true;
	```

	Build and run. This time you can login.

	<img width="25%" src="https://cloud.githubusercontent.com/assets/2589337/21619809/3fc4c4fc-d1e9-11e6-9ed0-5bd8a9baead5.gif" />

4. [Start Sync Gateway](../README.md#starting-sync-gateway) with the configuration file in this repository. Once logged into the app with a user that is defined in the [configuration file](https://github.com/couchbaselabs/mobile-training-todo/blob/master/sync-gateway-config.json#L9-L12), documents should be replicated to Sync Gateway.

> Android only: the sync URL is `localhost:4984` by default. Since Android emulators run in a separate VM you'll need to setup a reverse port forwarding rule (from the command line, run `adb reverse tcp:4984 tcp:4984`).
