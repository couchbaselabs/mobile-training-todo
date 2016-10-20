#!/usr/bin/env bash

# Install NGINX
sudo apt-get install nginx

# Update NGINX config with IPs
cp nginx_template.txt tmp.txt
for ip in "$@"
do
	echo "$ip"
	output="$(awk '{print} /sync_gateway_nodes/{print "server '${ip}':4984;"}' tmp.txt)"
	echo "$output" > tmp.txt
done

# Move NGINX config to /etc/nginx/sites-available/sync_gateway_nginx
mv tmp.txt /etc/nginx/sites-available/sync_gateway_nginx

# Enable the configuration file by creating a symlink
ln -s /etc/nginx/sites-available/sync_gateway_nginx /etc/nginx/sites-enabled/sync_gateway_nginx

# Restart NGINX
sudo service nginx restart