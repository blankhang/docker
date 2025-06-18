FROM jenkins/jenkins:lts-jdk21
MAINTAINER blankhang@gmail.com

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

ENV GRADLE_VERSION=8.14.2
ENV NODEJS_VERSION=22
ENV GRADLE_USER_HOME=/.gradle
ENV GRADLE_HOME=/opt/gradle
ENV ANDROID_HOME=/usr/lib/android-sdk/

# 安装基本工具 + 中文字体支持 + Docker CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git wget unzip curl fontconfig locales tzdata gnupg lsb-release ca-certificates \
    maven \
    && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers \
    && echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen && locale-gen zh_CN.UTF-8 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# 安装 Docker CLI（使用官方推荐方式）
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js（使用 NodeSource） + Yarn + pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn pnpm \
    && rm -rf /var/lib/apt/lists/*

# 安装 Gradle（自定义版本）
RUN curl -Lo /tmp/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip /tmp/gradle.zip -d /opt/ \
    && ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
    && rm -f /tmp/gradle.zip

# 创建并授权缓存目录
RUN mkdir -p ${GRADLE_USER_HOME}/caches /.android \
    && chown -R jenkins:jenkins ${GRADLE_USER_HOME} /.android

USER jenkins