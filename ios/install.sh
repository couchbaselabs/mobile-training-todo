#!/usr/bin/env bash

cd Frameworks
curl http://packages.couchbase.com/releases/couchbase-lite/ios/1.3.1/couchbase-lite-ios-community_1.3.1-6.zip > cbl.zip
unzip -n cbl.zip
rm -rf cbl.zip
rm -rf cbl