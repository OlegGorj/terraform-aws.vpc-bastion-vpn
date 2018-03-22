#!/bin/bash -v

sudo mkdir /var/log/tf/ ; sudo touch /var/log/tf/docker_install.log ; sudo chmod go+rw /var/log/tf/docker_install.log

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -  >> /var/log/tf/docker_install.log 2>&1

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"  >> /var/log/tf/docker_install.log 2>&1

sudo apt-get update >> /var/log/tf/docker_install.log 2>&1

apt-cache policy docker-ce >> /var/log/tf/docker_install.log 2>&1

sudo apt-get install -y docker-ce >> /var/log/tf/docker_install.log 2>&1


sudo docker pull nginx
sudo docker run --name docker-nginx —memory="900M" -p 80:80 -d nginx


# sudo touch touch /var/log/nginx.log; sudo chmod go+rw /var/log/nginx.log
# sudo apt-get install -y nginx > /var/log/nginx.log
# echo "\n This is NGiNX custom page - CIDR is ${cidr}, domain is ${domain} and hostname is `hostname` " > /tmp/index.html
# sudo cp /var/www/html/index.nginx-debian.html /var/www/html/index.nginx-debian.html.bk
# sudo cp /tmp/index.html /var/www/html/index.nginx-debian.html
#
# sudo systemctl start nginx
#
# sudo service nginx status


# #!/usr/bin/env bash
# sudo apt-get update
# sudo apt-get upgrade -y
# sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
# sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
# sudo apt-get update
# apt-cache policy docker-engine
# sudo apt-get install -y docker-engine
