
# Usage: ./build_deploy.zip [--download-rpms]

# Make a deploy directory
mkdir deploy

# Copy in .sh files
cp *.sh deploy

# Remove ourselves
rm deploy/build_deploy_zip.sh

# Copy in SG + nginx config
cp ../*.json deploy
cp *.txt deploy

# wget the appropriate rpms
cd deploy
if [ "$1" = "--download-rpms" ]; then
    wget http://packages.couchbase.com/releases/4.1.0/couchbase-server-community-4.1.0-centos6.x86_64.rpm
    wget http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.rpm
fi

# Zip it
cd ..
zip deploy.zip deploy/*

# Delete the deploy directory
rm -rf deploy
