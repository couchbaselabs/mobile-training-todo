## Configuration
The application can be configured via static variables defined in the TodoApp class.

* DB_DIR : The directory where you want the application to store the database.
* SYNC_ENABLED : Whether the replication should be enabled or not.
* SYNC_URL : Sync Gateway URL
* SYNC_CR_MODE : Conflict Resolution Mode (DEFAULT, LOCAL, and REMOTE)
* LOG_ENABLED : Whether the console logging at the verbose level should be enabled or not.

## Development Tool
* IntelliJ Community Edition
* JavaFX

## Requirement
* Java 11 <= V <= 18

## How to run

1. Using Gradle

 ```
 $gradlew run
 ```
2. Using IntelliJ

 * IntelliJ won't run this because it can't handle the missing module info for the com.couchbase.mobile.ee package

