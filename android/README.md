
## Configuration

The application can be configured for several different modes of use.  The configurable parameters are:

* Logging: turning logging on sets CBL logging to VERBOSE.  Turning it off sets it to ERROR
* Conflict Resolution: If turned on, the app will use a custom conflict resolver.  The custom resolver is very like the default resolver, but adds a value for the key "conflict" to the resolved document.
* Default DB name: Sets a default database name.  If a default database name is specified, and there the SG URL is empty, the app will never show the Login page
* SyncGateway URL: the url for the SG.

The default values for the application's configuration are 
```
    LOGGING_ENABLED = true
    CCR_ENABLED = false
    DB_NAME = null
    SG_URL = null
```

All of these parameters can be configured from the Config page, available in the app menu bar.
Changing any value on that page will force a logout.


## Building

### Requirements:

* Gradle 5.1.1
* Build tools: 29.0 2
* Build SDK: 29
* Min API: 24

### Build and run

Either open with Android Studio and run, or:

```./gradlew installDebug```

## TTD

* Restore photo capabilities
* Use Dagger to inject the Singletons
* Convert AsyncTasks to Rx, or something...
