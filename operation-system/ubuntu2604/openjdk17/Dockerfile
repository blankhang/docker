FROM blankhang/ubuntu2604
LABEL maintainer="blankhang <blankhang@gmail.com>" \
      version="1.0" \
      description="ubuntu26.04 with openjdk17 and chinese language and CST GMT+8 timezone support"

RUN apt update -qq \
 && DEBIAN_FRONTEND=noninteractive apt install -qqy --no-install-recommends openjdk-17-jdk ca-certificates-java \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && /var/lib/dpkg/info/ca-certificates-java.postinst configure
