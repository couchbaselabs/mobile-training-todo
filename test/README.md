## Getting Started

This folder contains the scripts for the Couchbase Mobile Training on performance testing. The **loadtest.js** script can be used to generate load on a Sync Gateway while the application is being used. Its implementation is based on the [loadtest](https://github.com/alexfernandez/loadtest) module. To get started, run the following.

- Install Node.js dependencies.

    ```bash
    npm install
    ```

- Start a Sync Gateway instance with the configuration file in the root of this repository.

    ```bash
    ~/Downloads/couchbase-sync-gateway/bin/sync_gateway sync-gateway-config.json
    ```

- Run the loadtest script.

    ```bash
    node loadtest.js
    ```

    By default, the script executes the **WriteAndReadDocument** scenario which inserts as many documents as possible in 20 concurrent processes for 6 seconds on a Sync Gateway running locally ([http://localhost:4985](http://localhost:4985)). Once the test has finished you will see the results in the console.

    ```bash
    Requests: 210
    Requests: 308
    Requests: 391

    Target URL:          http://localhost:4985/

    Completed requests:  392
    Mean latency:        294.2 ms

    Percentage of the requests served within a certain time
      50%      227 ms
      90%      610 ms
      95%      805 ms
      99%      1248 ms
    ```

- Open the Sync Gateway Admin UI ((http://localhost:4985/_admin/db/todo)[http://localhost:4985/_admin/db/todo]) to browse the documents that were inserted.

## Writing scenarios

To write scenarios you must first learn how to use the Sync Gateway client API. Read [this guide](http://developer.couchbase.com/documentation/mobile/current/guides/sync-gateway/rest-api-client/index.html#a-simple-web-application) to understand how to find the available command on the Sync Gateway client object and refer to the Sync Gateway [Admin API References](http://developer.couchbase.com/documentation/mobile/current/references/sync-gateway/admin-rest-api/index.html).