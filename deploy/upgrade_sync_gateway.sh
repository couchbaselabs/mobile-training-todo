#!/usr/bin/env bash

# Stop Sync Gateway
service sync_gateway stop

# Uninstall Sync Gateway 1.3.0
dpkg -r couchbase-sync-gateway
dpkg -P couchbase-sync-gateway

# Download and Sync Gateway 1.3.1
wget http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
dpkg -i couchbase-sync-gateway-community_1.3.1-16_x86_64.deb