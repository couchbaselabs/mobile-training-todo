#!/usr/bin/env bash

# Download Sync Gateway 1.3
wget http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.0/couchbase-sync-gateway-enterprise_1.3.0-274_x86_64.deb

# Install Sync Gateway 1.3
dpkg -i couchbase-sync-gateway-enterprise_1.3.0-274_x86_64.deb

# Update Sync Gateway config with Couchbase Server URL
sed 's/walrus:/http:\/\/'${1}':8091/g' sync-gateway-config.json > sync_gateway.json

# Replace the default config file with the one from the app
mv sync_gateway.json /home/sync_gateway/sync_gateway.json

# Restart the sync_gateway service
service sync_gateway restart