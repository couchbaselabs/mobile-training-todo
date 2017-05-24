## Getting Started 

To run the app, open the folder for the platform of your choice (**android**, **dotnet** or **ios**) and follow the instructions in the respective README.

### Starting Sync Gateway

1. [Download Sync Gateway](http://www.couchbase.com/nosql-databases/downloads#couchbase-mobile).
2. Start Sync Gateway with the configuration file in the root of this project.

    ```bash
    ~/Downloads/couchbase-sync-gateway/bin/sync_gateway sync-gateway-config.json
    ```

3. Add lists and tasks and they should be visible on the Sync Gateway Admin UI on [http://localhost:4985/_admin/](http://localhost:4985/_admin/).

### Moderators

The configuration file creates a few users [by default](https://github.com/couchbaselabs/mobile-training-todo/blob/master/sync-gateway-config.json#L8-L13). Users with the moderator role can:

- Update/delete any user's list.
- Have access to all the lists in the system.
- Can invite any number of users to a list.

The role created in Sync Gateway enforces security in the Sync Function. Couchbase Lite on the other hand can't tell if the user is a moderator. For that reason, the app uses another document of type "moderator" to detect the user's status and permissions. The "moderator" document can be created through the Admin REST API with the following.

```bash
curl -X POST 'http://localhost:4985/todo/' \
      -H 'Content-Type: application/json' \
      -d '{"_id": "moderator.mod", "type": "moderator", "username": "mod"}'
```
