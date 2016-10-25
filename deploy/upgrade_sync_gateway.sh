#!/usr/bin/env bash

set -e
set -x

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Stop Sync Gateway
service sync_gateway stop

# Uninstall Sync Gateway 1.3.0
sudo systemctl stop sync_gateway
rpm -e couchbase-sync-gateway-community_1.3.0-274_x86_64.rpm

# Download and Sync Gateway 1.3.1
if [ ! -f couchbase-sync-gateway-community_1.3.1-16_x86_64.rpm ]; then
    wget http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.rpm
fi
rpm -i couchbase-sync-gateway-community_1.3.1-16_x86_64.rpm