FROM rabbitmq:4.1.1-management-alpine

LABEL maintainer="blankhang <blankhang@gmail.com>"

ENV VERSION=4.1.1
ENV DELAYED_MESSAGE_EXCHANGE_VERSION=4.1.0
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apk update && \
    apk add --no-cache curl tzdata \
        musl-locales \
        musl-locales-lang \
        icu-libs \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && curl -fSL "https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v${DELAYED_MESSAGE_EXCHANGE_VERSION}/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez" \
         -o "$RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez" \
    && chown rabbitmq:rabbitmq "$RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez" \
    && rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange \
                                rabbitmq_consistent_hash_exchange \
                                rabbitmq_mqtt \
                                rabbitmq_web_mqtt \
                                rabbitmq_web_stomp \

#/etc/rabbitmq/enabled_plugins
ADD config/enabled_plugins /etc/rabbitmq/enabled_plugins

# 可选配置文件
ADD config/rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
