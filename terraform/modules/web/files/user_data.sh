#!/bin/bash -v
apt-get update -y
apt-get install -y nginx > /var/nginx.log
#sudo sed  's/Thank you for using nginx/This is custom page - CIDR is ${cidr}, domain is ${domain} /g' /var/www/html/index.nginx-debian.html > /tmp/index.html
echo "\n This is NGiNX custom page - CIDR is ${cidr}, domain is ${domain} and hostname is `hostname` " > /tmp/index.html
sudo cp /var/www/html/index.nginx-debian.html /var/www/html/index.nginx-debian.html.bk
sudo cp /tmp/index.html /var/www/html/index.nginx-debian.html
