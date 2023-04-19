# https://github.com/jenkinsci/docker/blob/master/README.md
FROM jenkins/jenkins:lts
MAINTAINER blankhang@gmil.com

USER root

# install docker cli
RUN apt-get -y update; apt-get install -y sudo; apt-get install -y git wget
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers
RUN wget http://get.docker.com/builds/Linux/x86_64/docker-latest.tgz
RUN tar -xvzf docker-latest.tgz
RUN mv docker/* /usr/bin/

# update system and install chinese language support and maven nodejs
RUN apt-get update && apt-get install -y locales locales-all maven nodejs \
    && sed -i '/^#.* zh_CN.UTF-8 /s/^#//' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/* \

# Setting Default Chinese Language and UTC+8 timezone
#ENV LANG C.UTF-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8
ENV TZ Asia/Shanghai

USER jenkins