#!/bin/sh

wait_for_uri() {
  expected=$1
  shift
  uri=$1
  echo "Waiting for $uri to be available..."
  while true; do
    status=$(curl -s -w "%{http_code}" -o /dev/null $*)
    if [ "x$status" = "x$expected" ]; then
      break
    fi
    echo "$uri not up yet (status=$status), waiting 5 seconds..."
    sleep 5
  done
  echo "$uri ready, continuing"
}

create_user() {
  curl --silent --location --request POST 'http://sg:4985/todo/_user/' \
  --user "admin:password" \
  --header 'Content-Type: application/json' \
  --data "{
      \"name\": \"$1\",
      \"password\": \"pass\",
      \"collection_access\": {
          \"_default\": {
              \"lists\": {\"admin_channels\": []},
              \"tasks\": {\"admin_channels\": []},
              \"users\": {\"admin_channels\": []}
          }
      }
  }"
}

# Wait for SG to be ready:
sleep 30
wait_for_uri 200 http://sg:4984

echo "Configure SG Database and Collections ..."
# Configure database and collections:
curl --silent --location --request PUT 'http://sg:4985/todo/' \
--user "admin:password" \
--header "Content-Type: application/json" \
--data @db.json

# Update config with sync functions:
echo "Configure Sync Functions ..."
curl --silent --location --request PUT 'http://sg:4985/todo/_config' \
--user "admin:password" \
--header "Content-Type: application/json" \
--data @sync-function.json

# Add testing users (password is 'pass'):
echo "Add some test users ..."
create_user "blake"
create_user "callum"
create_user "dan"
create_user "jens"
create_user "jianmin"
create_user "jim"
create_user "pasin"
create_user "vlad"
create_user "user1"
create_user "user2"
create_user "user3"

echo "DONE!"