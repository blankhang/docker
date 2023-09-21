# https://github.com/jenkinsci/docker/blob/master/README.md
FROM jenkins/jenkins:lts
MAINTAINER blankhang@gmail.com

USER root

# install docker cli
RUN apt -y update; apt install -y sudo; apt install -y git wget \
  && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers \
  && wget http://get.docker.com/builds/Linux/x86_64/docker-latest.tgz \
  && tar -xvzf docker-latest.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -rf docker docker-latest.tgz

# update system and install chinese language support and maven nodejs npm
RUN apt update && apt install -y locales locales-all maven nodejs npm  \
    && sed -i '/^#.* zh_CN.UTF-8 /s/^#//' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn pnpm

# Setting Default Chinese Language and UTC+8 timezone
#ENV LANG C.UTF-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8
ENV TZ Asia/Shanghai

USER jenkins