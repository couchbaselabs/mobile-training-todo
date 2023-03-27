#!/bin/sh

if [ "$#" -ne 2 ]; then
    echo "Usage: run.sh <Sync-Gateway-Config-File> <Log-Directory>"
    exit 1
fi

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
    echo "$uri not up yet, waiting 5 seconds..."
    sleep 5
  done
  echo "$uri ready, continuing"
}

# Stop sync_gateway service:
echo "Stop running sync_gateway service ..."
systemctl stop sync_gateway

wait_for_uri 200 http://cb-server:8091/pools/default/buckets/todo -u admin:password
echo "Sleeping for 10 seconds to give server time to settle..."
sleep 10

# Start sync_gateway:
echo "Start sync_gateway ..."
/opt/couchbase-sync-gateway/bin/sync_gateway "$1" 2>&1 | tee "$2/sg.log"