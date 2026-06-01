# https://hub.docker.com/_/rabbitmq
FROM rabbitmq:4.3.1-management

LABEL maintainer="blankhang <blankhang@gmail.com>"

ENV VERSION=4.3.1

# Set UTF-8 locale and timezone.
ENV LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

# Install dependencies and setup timezone
RUN apt update && apt install -y curl tzdata locales \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && locale-gen C.UTF-8 \
    && update-locale LANG=C.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Enable plugins (offline mode)
RUN rabbitmq-plugins enable --offline \
      rabbitmq_consistent_hash_exchange \
      rabbitmq_mqtt \
      rabbitmq_web_mqtt \
      rabbitmq_web_stomp

# Add plugins and config files
ADD config/enabled_plugins /etc/rabbitmq/enabled_plugins
ADD config/rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
