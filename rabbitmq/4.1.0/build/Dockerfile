# https://hub.docker.com/_/rabbitmq

FROM rabbitmq:4.0.9-management

LABEL maintainer="blankhang <blankhang@gmail.comm>"

ENV VERSION=4.0.9
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive


RUN apt update && apt install -y curl tzdata \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# 使用与RabbitMQ 4.0.9兼容的延迟消息交换插件版本
RUN curl -L https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v4.0.7/rabbitmq_delayed_message_exchange-4.0.7.ez > $RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-4.0.7.ez

RUN chown rabbitmq:rabbitmq $RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-${VERSION}.ez

RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange rabbitmq_consistent_hash_exchange rabbitmq_mqtt

# only need when upgrad from old version
#RUN rabbitmqctl enable_feature_flag all || true

#/etc/rabbitmq/enabled_plugins
ADD config/enabled_plugins /etc/rabbitmq/enabled_plugins

ADD config/rabbitmq.conf /etc/rabbitmq/conf.d/mq.conf
