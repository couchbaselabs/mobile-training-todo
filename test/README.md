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

    By default, the script creates lists for each user specified in the `users` option. Then it inserts as many tasks as possible concurrently and during the specified time. Once the test has finished you will see the results in the console.

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

- Open the Sync Gateway Admin UI ([http://localhost:4985/_admin/db/todo](http://localhost:4985/_admin/db/todo)) to browse the documents that were inserted.

- Run the app on the platform of your choice against the same Sync Gateway instance and login as a moderator (**mod/pass**) to view all the lists.

<img src="https://cloud.githubusercontent.com/assets/2589337/21888924/57c55c84-d8be-11e6-8436-409afdc2d79a.png" width="25%" />
<img src="https://cloud.githubusercontent.com/assets/2589337/21888850/01c0a848-d8be-11e6-8b2d-72566bf5cb2a.png" width="25%" />
<img src="https://cloud.githubusercontent.com/assets/2589337/21889017/c4089aa0-d8be-11e6-9eb1-5bef4f202bbb.png" width="25%" />

## Writing scenarios

To write scenarios you must first learn how to use the Sync Gateway client API. Read [this guide](http://developer.couchbase.com/documentation/mobile/current/guides/sync-gateway/rest-api-client/index.html#a-simple-web-application) to understand how to find the available command on the Sync Gateway client object and refer to the Sync Gateway [Admin API References](http://developer.couchbase.com/documentation/mobile/current/references/sync-gateway/admin-rest-api/index.html).
