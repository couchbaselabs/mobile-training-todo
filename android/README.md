## Getting Started

### Configuration

You can enable functionalities individually. By default, they are all disabled and can be modified in **Application.java**.

```swift
private Boolean mLoginFlowEnabled = true;
private Boolean mEncryptionEnabled = false;
private Boolean mSyncEnabled = true;
private String mSyncGatewayUrl = "http://10.0.2.2:4984/todo/";
private Boolean mLoggingEnabled = false;
private Boolean mUsePrebuiltDb = false;
private Boolean mConflictResolution = false;
```

### Building

1. Open **android/build.gradle** in Android Studio.
2. Build and run.
