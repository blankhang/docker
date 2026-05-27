#!/bin/bash

# create jenkins local data store directory
mkdir  -p /docker/jenkins/jenkins_home
chmod 755 /docker/jenkins/jenkins_home

# create jenkins's Dockerfile file
cat << 'EOF' > /docker/jenkins/Dockerfile
# https://github.com/jenkinsci/docker/blob/master/README.md
# FROM jenkins/jenkins:jdk11
FROM jenkins/jenkins:lts-jdk11
MAINTAINER blankhang@gmail.com

user root

# update system and install chinese language support
RUN apt-get update && apt-get install -y locales locales-all maven nodejs \
    && sed -i '/^#.* zh_CN.UTF-8 /s/^#//' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# Setting Default Chinese Language and UTC+8 timezone
#ENV LANG C.UTF-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8
ENV TZ Asia/Shanghai

user jenkins
EOF


# create jenkins's docker-compose file
cat << 'EOF' > /docker/jenkins/docker-compose.yml
version: '3.7'

services:
  jenkins:
    build:
      dockerfile: Dockerfile
      context: .
    #image: jenkins/jenkins:jdk11
    container_name: jenkins
    restart: always
    privileged: true
    user: root
    healthcheck:
      test: curl -s https://localhost:8080 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 1m
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.90'
#    environment:
      #LANG: "zh_CN.UTF-8"
      #LANGUAGE: "zh_CN.UTF-8"
      #LC_ALL: "zh_CN.UTF-8"
      #TZ: "Asia/Shanghai"
    ports:
      - '8080:8080'
    networks:
      - default
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

# create start.sh file
cat << 'EOF' > /docker/jenkins/start.sh
#!/bin/bash

# start jenkins
docker-compose -f /docker/jenkins/docker-compose.yml up -d
EOF

#set the start.sh file permission so it can run without issue
chmod 755 /docker/jenkins/start.sh

#build jenkins docker image
docker-compose build

echo -e "\033[36m init success \033[0m"
echo "now you can run start.sh to start jenkins"