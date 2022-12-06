FROM ubuntu:22.04
MAINTAINER blankhang <blankhang@gmail.com>
LABEL version='1.0' description='ubuntu22.04 with chinese lanugage and CST GMT+8 timezone support'

# All of the necessary packages required apparently. Might want to confirm
# which are actually needed.
RUN apt-get -qq update \
  && apt-get install -qqy --no-install-recommends \
    bzip2 \
    unzip \
    curl \
    net-tools \
    telnet \
    fonts-droid-fallback \
    ttf-wqy-zenhei \
    ttf-wqy-microhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    locales \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN locale-gen zh_CN.UTF-8
ENV LANG='zh_CN.UTF-8' LANGUAGE='zh_CN:zh:en_US:en' LC_ALL='zh_CN.UTF-8'

# Not sure why this is done, must dig in more later.
RUN rm -f /etc/ssl/certs/java/cacerts; \
  /var/lib/dpkg/info/ca-certificates-java.postinst configure