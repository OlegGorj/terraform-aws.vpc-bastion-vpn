#!/bin/bash -v

sudo mkdir /var/log/tf/ ; chown -R ubuntu:ubuntu /var/log/tf/

# Install utilities
# Ensure dependencies are installed
sudo apt install -y yum       > /var/log/tf/yum_install.log 2>&1
yum install -y epel-release   >> /var/log/tf/yum_install.log 2>&1
yum update -y epel-release    >> /var/log/tf/yum_install.log 2>&1
yum install -y python-pip \
    python-devel \
    git \
    openssl-devel \
    libffi-devel \
    awscli \
    python-six \
    python-boto \
    python-jinja2 \
    python-demjson \
    apt-transport-https \
    software-properties-common \
    ansible   >> /var/log/tf/yum_install.log 2>&1

pip install --upgrade pip
pip install --upgrade setuptools


# Install Docker engine
sudo touch /var/log/tf/docker_install.log ; sudo chmod go+rw /var/log/tf/docker_install.log

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -  >> /var/log/tf/docker_install.log 2>&1

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"  >> /var/log/tf/docker_install.log 2>&1

sudo apt-get update >> /var/log/tf/docker_install.log 2>&1

apt-cache policy docker-ce >> /var/log/tf/docker_install.log 2>&1

sudo apt-get install -y docker-ce >> /var/log/tf/docker_install.log 2>&1

echo "INFO: `date`: Docker package installation complete.."  >> /var/log/tf/docker_install.log


# Get the github.com SSH information so we don't get prompted when pulling code
# ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
# command
cp /root/.ssh/known_hosts /home/${TERRAFORM_user}/.ssh/known_hosts
chown ${TERRAFORM_user}:${TERRAFORM_user} /home/${TERRAFORM_user}/.ssh/known_hosts

#
