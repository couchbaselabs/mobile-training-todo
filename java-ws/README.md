# ToDo Web Service

## Overview

The ToDo Web Service is, first of all, a mess.  It has barely been tested, less used, and is brittle
as all get out.

The basic architecture is two web services.  The first is a REST service that runs under Jetty.
It is in the directory `server`.  It uses CBL-Java to manipulate a standard ToDo database
and serves a simple Open API REST interface.

The second web service is a Node.js service that talks to the first server's REST API.
It is in the directory `client`.  It presents the ToDo UI to a browser.

To run this thing you need to start the REST server, then start the "client" server and then
navigate to the client server with your browser.

## Starting the REST Server

1.  From the directory server/Todo, use gradle to embedded Jetty:

```
./gradlew jettyRun
```
You should see something like this:
```
15:38:07 INFO  Configuring / with file:<project root>java-ws/server/Todo/config/META-INF/jetty-env.xml
02-14 15:38:08.201      1 I/CouchbaseLite/DATABASE: [JAVA] CBL-ANDROID Initialized: CouchbaseLite Java v3.1.0-SNAPSHOT (EE/release Build/SNAPSHOT Commit/unofficial@HQ-Rename0337 Core/3.1.0 (326)) Java 11.0.11; Mac OS X
> Database Directory: CouchbaseLiteDb
> Sync Gateway URL: 
> Verbose Logging: true
> Login Required: true
> Custom Conflict Resolution: default
> Max retries: 0
> Wait time: 0
15:38:08 INFO  Jetty 11.0.11 started and listening on port 8080
15:38:08 INFO   runs at:
15:38:08 INFO    http://localhost:8080/
```

2. The lines in the startup log that begin with '> ' show the application configuration.
That configuration is set up in the file `config/META-INF/jetty-env.xml`.  You can change the
configuration by editing that file. In particular, if you leave the Sync Gateway URL empty,
the REST Service will not attmpt to connect to a SGW.  If the value is non-null, the REST server
will attempt to start a Replicator with the given URL as the target endpoint.

_Note that the `jetty-env.xml` file only works in its current location, when using gretty
(the jetty plugin for gradle).  To run the service standalone, make sure to copy the same configuration
file into the deployed web app._

3. There is a Sync Gateway configureation file, `sync-gateway-config.json` located at the root of the repository.
It may be useful...

 ```
 ./sync_gateway ../config/sync-gateway-config.json
 ```

## Starting the UI server

1. Be sure you have npm installed.  On a Mac you can use brew to install npm.  Then:

```
npm install
```

Now run the UI server:
```
npm run serve
```
If you must specify a particular port (the default is the first free port >= 8080):

```
npm run serve -- --port <port number>
```

The server will spew all kinds of stuff (I hope none of it is very important).
It should, finally, though, say something like this:

```
 DONE  Compiled successfully in 15689ms

  App running at:
  - Local:   http://localhost:8081/ 
  - Network: http://192.168.1.22:8081/

  Note that the development build is not optimized.
  To create a production build, run npm run build.
```

1. You may now use your browser to navigate to the UI.  It is at:
```
http://localhost:8081/login
```



