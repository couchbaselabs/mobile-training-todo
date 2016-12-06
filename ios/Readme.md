## Getting Started

### Installing Couchbase Lite

1. Change to ios directory.

  ```
  cd ios
  ```

2. Run installation script (downloads Couchbase Lite to **Frameworks** folder).

  ```
  ./install.sh
  ```

### Configuration

You can enable functionalities individually. By default, they are all disabled and can be modified in **AppDelegate.swift**.

```swift
let kLoginFlowEnabled = true
let kEncryptionEnabled = false
let kSyncEnabled = true
let kSyncGatewayUrl = URL(string: "http://localhost:4984/todo/")!
let kLoggingEnabled = false
let kUsePrebuiltDb = false
let kConflictResolution = false
```

### Building

1. Open **Todo.xcodeproj** in Xcode.
2. Build and run.
