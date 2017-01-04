## Getting Started

    ```bash
    git clone https://github.com/couchbaselabs/mobile-training-todo.git
    cd mobile-training-todo/react-native
    npm install && react-native start
    ```

_(Optional)_ Start Sync Gateway with the configuration in the root of this repository.

    ```bash
    cd mobile-training-todo
    $ ~/Downloads/couchbase-sync-gateway/bin/sync_gateway sync-gateway-config.json
    ```
    
### iOS
    
1. Open **ios/ReactNativeCouchbaseLiteExample.xcodeproj** in Xcode.
2. Build and run. You should see an empty screen, use the red button to add a list.

	<img width="25%" src="https://cloud.githubusercontent.com/assets/2589337/21619898/abefd0cc-d1e9-11e6-8e8a-5bb2d39f0911.png" />

3. Open **app/DataManager.js** and set the following flags to `true`.

	```bash
	global.LOGIN_FLOW_ENABLED = true;
	const SYNC_ENABLED = true;
	```

	Build and run. This time you can login.

	<img width="25%" src="https://cloud.githubusercontent.com/assets/2589337/21619809/3fc4c4fc-d1e9-11e6-9ed0-5bd8a9baead5.gif" />

### Android

1. Open **android** in AndroidStudio
2. Refresh the gradle project and run