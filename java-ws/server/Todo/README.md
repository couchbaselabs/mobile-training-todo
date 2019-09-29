#Java WebService for Todo Application

###How to run the service?

1. Run Sync Gateway with the sync-gateway-config.json from the config folder located at the root of the repository.

 ```
 ./sync_gateway ../config/sync-gateway-config.json
 ```

 ** Sync Gateway can be download from www.couchbase.com.

2. Download couchbase-lite-java and put all of the jar files in the lib folder. 

 ** Note that this is a temporary solution until couchbase-lite-java has been deployed to meaven or jcenter repository.

3. Configure directory to store databases and Sync Gateway endpoint URL in `config/META-INF/context.xml`. 

 ** Note that the context.xml here is only for running the application with the embeded tomcat. To run the service on a standalone tomcat, make sure to copy the same configuration into the deployed context.xml (see [here](https://tomcat.apache.org/tomcat-7.0-doc/config/context.html) for more info).

4. For development and test, run the service using the embeded tomcat.

 ```
 ./gradlew tomcatRun
 ```

  The service will be started at port 8080 by default. To change the port, edit tomcat.httpPort in build.gradle.

5. To generate a war file for deployment on a standalone tomcat,

 ```
 ./gradlew war
 ```
 