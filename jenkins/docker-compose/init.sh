#!/bin/bash

# create jenkins local data store directory
mkdir  -p /docker/jenkins/jenkins_home
chmod 755 /docker/jenkins/jenkins_home

# create jenkins's docker-compose file
cat << 'EOF' > /docker/jenkins/docker-compose.yml
version: '3.7'

services:
  jenkins:
    image: jenkinsci/blueocean
    container_name: jenkins
    restart: always
    privileged: true
    user: root
    healthcheck:
      test: curl -s https://localhost:8080 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 1m
      timeout: 5s
      retries: 3
      start_period: 3s
    environment:
      TZ : "Asia/Shanghai"
    ports:
      - '8080:8080'
    networks:
      - default
#    extra_hosts:
#      - "blankhang.t :177.177.177.177"
    volumes:
      - '/app:/app'
      - '/usr/share/fonts:/usr/share/fonts'
      - '/docker/jenkins/jenkins_home:/var/jenkins_home'
      - '/etc/localtime:/etc/localtime:ro'
      - '/var/run/docker.sock:/var/run/docker.sock'
      - '/usr/lib/x86_64-linux-gnu/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7'
      - '~/.ssh:/var/jenkins_home/.ssh'
      - '~/.m2:/root/.m2'
networks:
  default:
EOF

echo -e "\033[36m init success \033[0m"
echo "now you can run start.sh to start jenkins"