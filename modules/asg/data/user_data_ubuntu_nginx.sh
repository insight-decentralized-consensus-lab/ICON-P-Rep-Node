#!/bin/bash
# Install docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce
usermod -aG docker ubuntu

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

cat <<EOF >/home/ubuntu/docker-compose.yml
version: '3'
services:
     container:
          image: 'iconloop/prep-node:1905292100xdd3e5a'
          container_name: 'prep-node'
          volumes:
               - ./data:/data
          ports:
               - 9000:9000
               - 7100:7100
EOF
/usr/local/bin/docker-compose -f /home/ubuntu/docker-compose.yml up -d
