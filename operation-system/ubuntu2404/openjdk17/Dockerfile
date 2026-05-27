FROM blankhang/ubuntu2404
LABEL maintainer="blankhang <blankhang@gmail.com>" \
      version="1.0" \
      description="ubuntu24.04 with openjdk17 and chinese language and CST GMT+8 timezone support"

# All of the necessary packages required apparently. Might want to confirm
# which are actually needed.
RUN apt update  -qq  \
  && apt install -qqy --no-install-recommends  openjdk-17-jdk \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && rm -f /etc/ssl/certs/java/cacerts; \
  && /var/lib/dpkg/info/ca-certificates-java.postinst configure