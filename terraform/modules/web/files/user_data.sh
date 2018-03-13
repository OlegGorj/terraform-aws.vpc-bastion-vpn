#!/bin/bash
apt-get update -y
apt-get install -y nginx > /var/nginx.log
sudo sed  's/Thank you for using nginx/This is custom page/g' /var/www/html/index.nginx-debian.html > /tmp/index.html
sudo cp /tmp/index.html /var/www/html/index.nginx-debian.html
