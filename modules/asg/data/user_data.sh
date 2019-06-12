#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

REGION=${region}

export PATH=/usr/local/bin:$PATH;

yum update
yum install docker -y
service docker start
usermod -a -G docker ec2-user
curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
chown root:docker /usr/local/bin/docker-compose
cat <<EOF >/home/ec2-user/docker-compose.yml
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
chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml
/usr/local/bin/docker-compose -f /home/ec2-user/docker-compose.yml up -d
