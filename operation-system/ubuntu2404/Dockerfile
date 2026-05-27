FROM ubuntu:24.04
LABEL maintainer="blankhang <blankhang@gmail.com>"
LABEL version="1.0" description="ubuntu24.04 with chinese language and CST GMT+8 timezone support"

RUN apt-get -qq update \
  && apt-get install -qqy --no-install-recommends \
    bzip2 \
    unzip \
    curl \
    net-tools \
    telnet \
    fonts-noto-cjk \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    locales \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8
ENV LANG="zh_CN.UTF-8" LANGUAGE="zh_CN:zh:en_US:en" LC_ALL="zh_CN.UTF-8"
