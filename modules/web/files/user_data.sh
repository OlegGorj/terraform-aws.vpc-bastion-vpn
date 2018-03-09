#!/bin/bash
apt-get update -y
apt-get install -y nginx > /var/nginx.log
cd /usr/share/nginx/html
sudo sed  's/Thank you for using nginx/This is custom page/g' index.html > /tmp/index.html
sudo cp /tmp/index.html ./index.html
