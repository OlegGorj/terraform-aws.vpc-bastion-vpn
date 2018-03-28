#!/bin/bash -v

# set permission for logs dir
sudo chmod go+rw  /var/log/tf/

# Get the dockerfile from the repository
sudo su - ${TERRAFORM_user}
cd ~/; git clone https://github.com/OlegGorj/nginx-docker-minimal.git > /var/log/tf/nginx_install.log  2>&1

cd nginx-docker-minimal; docker build .  >> /var/log/tf/nginx_install.log 2>&1

docker run --name docker-nginx-alpine --memory="900M" -p 80:80 -d nginx:alpine  >> /var/log/tf/nginx_install.log 2>&1

echo "INFO: `date`: cloning repo nginx-docker complete.."  >> /var/log/tf/nginx_install.log  2>&1
