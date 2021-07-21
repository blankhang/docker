# https://github.com/jenkinsci/docker/blob/master/README.md
FROM jenkins/jenkins:jdk11
MAINTAINER blankhang@gmil.com

user root

# update system and install chinese language support
RUN apt-get update && apt-get install -y maven nodejs \
    && sed -i '/^#.* zh_CN.UTF-8 /s/^#//' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# Setting Default Chinese Language
ENV LANG: "zh_CN:UTF-8"
ENV LANGUAGE: "zh_CN:zh"
ENV LC_ALL: "zh_CN:UTF-8"

user jenkins