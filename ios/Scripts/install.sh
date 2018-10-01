#!/usr/bin/env bash

cd Frameworks
curl https://packages.couchbase.com/releases/couchbase-lite/ios/1.4.0/couchbase-lite-ios-enterprise_1.4.0-3.zip > cbl.zip
unzip -n cbl.zip
rm -rf cbl.zip
rm -rf cbl