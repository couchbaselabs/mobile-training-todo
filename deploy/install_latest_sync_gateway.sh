#!/usr/bin/env bash

set -e
set -x

if [ "$#" -ne 1 ]; then
    echo "You must pass the IP of the Couchbase Server VM"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Download Sync Gateway 1.3.1
if [ ! -f couchbase-sync-gateway-community_1.3.1-16_x86_64.rpm ]; then
    wget http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.rpm
fi

# Install Sync Gateway 1.3.1
rpm -i couchbase-sync-gateway-community_1.3.1-16_x86_64.rpm

# Update Sync Gateway config with Couchbase Server URL
sed 's/walrus:/http:\/\/'${1}':8091/g' sync-gateway-config.json > sync_gateway.json

# Replace the default config file with the one from the app
mv sync_gateway.json /home/sync_gateway/sync_gateway.json

# Restart the sync_gateway service
service sync_gateway restart
