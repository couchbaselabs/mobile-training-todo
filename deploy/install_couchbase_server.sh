#!/usr/bin/env bash

# Download Couchbase Server 4.1
wget http://packages.couchbase.com/releases/4.1.0/couchbase-server-community_4.1.0-ubuntu14.04_amd64.deb

# Install Couchbase Server 4.1
dpkg -i couchbase-server-community_4.1.0-ubuntu14.04_amd64.deb

# Waiting for server
sleep 10

# Initialize the cluster and a new user (Administrator/password)
/opt/couchbase/bin/couchbase-cli cluster-init -c 127.0.0.1 --cluster-init-username=Administrator --cluster-init-password=password --cluster-init-ramsize=600 -u admin -p password

# Create a new bucket called todo
/opt/couchbase/bin/couchbase-cli bucket-create -c 127.0.0.1:8091 --bucket=todo --bucket-type=couchbase --bucket-port=11211 --bucket-ramsize=600 --bucket-replica=1 -u Administrator -p password