# https://hub.docker.com/_/rabbitmq

FROM rabbitmq:4.1.1-management

LABEL maintainer="blankhang <blankhang@gmail.comm>"

ENV VERSION=4.1.1
ENV DELAYED_MESSAGE_EXCHANGE_VERSION=4.1.0
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive


RUN apt update && apt install -y curl tzdata \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v${DELAYED_MESSAGE_EXCHANGE_VERSION}/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez > $RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez

RUN chown rabbitmq:rabbitmq $RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez

RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange rabbitmq_consistent_hash_exchange rabbitmq_mqtt rabbitmq_web_mqtt rabbitmq_web_stomp

# only need when upgrad from old version
#RUN rabbitmqctl enable_feature_flag all || true

#/etc/rabbitmq/enabled_plugins
ADD config/enabled_plugins /etc/rabbitmq/enabled_plugins

# config file
ADD config/rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
