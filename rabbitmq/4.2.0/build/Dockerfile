# https://hub.docker.com/_/rabbitmq
FROM rabbitmq:4.2.0-management

LABEL maintainer="blankhang <blankhang@gmail.com>"

ENV VERSION=4.2.0
ENV DELAYED_MESSAGE_EXCHANGE_VERSION=4.2.0

# ✅ 设置 UTF-8 locale 和时区，修复 latin1 警告
ENV LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

# 安装依赖 + 设置时区
RUN apt update && apt install -y curl tzdata locales \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && locale-gen C.UTF-8 \
    && update-locale LANG=C.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# 下载并启用 rabbitmq_delayed_message_exchange 插件
RUN curl -L \
      https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v${DELAYED_MESSAGE_EXCHANGE_VERSION}/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez \
      -o $RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez \
    && chown rabbitmq:rabbitmq $RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_EXCHANGE_VERSION}.ez

# 启用插件（离线模式）
RUN rabbitmq-plugins enable --offline \
      rabbitmq_delayed_message_exchange \
      rabbitmq_consistent_hash_exchange \
      rabbitmq_mqtt \
      rabbitmq_web_mqtt \
      rabbitmq_web_stomp

# 可选：当从旧版本升级到 4.2.0 时，手动启用 feature flag
# ⚠️ 新版本不能使用 all_stable，要用 rabbitmq_4.2.0
# RUN rabbitmqctl enable_feature_flag rabbitmq_4.2.0 || true

# 添加插件和配置文件
ADD config/enabled_plugins /etc/rabbitmq/enabled_plugins
ADD config/rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
