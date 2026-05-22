FROM blankhang/ubuntu2404
LABEL maintainer="blankhang <blankhang@gmail.com>" \
      version="1.0" \
      description="ubuntu24.04 with openjdk25 and chinese language and CST GMT+8 timezone support"

# All of the necessary packages required apparently. Might want to confirm
# which are actually needed.
RUN apt update -qq \
 && DEBIAN_FRONTEND=noninteractive apt install -qqy --no-install-recommends openjdk-25-jdk ca-certificates-java \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && /var/lib/dpkg/info/ca-certificates-java.postinst configure