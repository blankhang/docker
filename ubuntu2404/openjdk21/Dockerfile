FROM blankhang/ubuntu2404
LABEL maintainer="blankhang <blankhang@gmail.com>" \
      version="1.0" \
      description="ubuntu24.04 with openjdk21 and chinese language and CST GMT+8 timezone support"

# All of the necessary packages required apparently. Might want to confirm
# which are actually needed.
RUN apt-get -qq update \
  && apt-get install -qqy --no-install-recommends \
    openjdk-21-jdk \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
# Not sure why this is done, must dig in more later.
 && rm -f /etc/ssl/certs/java/cacerts; \
  /var/lib/dpkg/info/ca-certificates-java.postinst configure