#!/usr/bin/env bash

set -e
set -x

if [ "$#" -eq 0 ]; then
    echo "You must pass the IP of at least one Sync Gateway"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ ! -f nginx_template.txt ]; then
    echo "Could not find nginx_template.txt"
    exit 1
fi

# Update NGINX config with IPs
cp nginx_template.txt tmp.txt
for ip in "$@"
do
	echo "$ip"
	output="$(awk '{print} /sync_gateway_nodes/{print "server '${ip}':4984;"}' tmp.txt)"
	echo "$output" > tmp.txt
done

# Move NGINX config to /etc/nginx/sites-available/sync_gateway_nginx
mv tmp.txt /etc/nginx/conf.d/sync_gateway_nginx.conf

# Restart NGINX
sudo service nginx restart
