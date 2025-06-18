FROM jenkins/jenkins:lts-jdk21
LABEL maintainer="blankhang@gmail.com"

USER root

# 设置时区 & 中文语言环境
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8

# 安装基本工具 + 中文 + Maven + Node.js + Yarn + pnpm
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl wget unzip gnupg2 software-properties-common fontconfig \
    locales tzdata ca-certificates git maven lsb-release \
    && echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen zh_CN.UTF-8 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

# 安装 Docker CLI（不包含守护进程）
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli \
    && usermod -aG docker jenkins \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js 22 + Yarn + pnpm
ENV NODEJS_VERSION=22
RUN curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn pnpm \
    && rm -rf /var/lib/apt/lists/*

# 安装 Gradle
ENV GRADLE_VERSION=8.14.2 \
    GRADLE_HOME=/opt/gradle
RUN curl -Lo /tmp/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip /tmp/gradle.zip -d /opt/ \
    && ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
    && rm /tmp/gradle.zip

# 安装 Android SDK 工具
ENV ANDROID_HOME=/opt/android-sdk-linux \
    ANDROID_SDK_ROOT=/opt/android-sdk-linux \
    PATH=$PATH:/opt/android-sdk-linux/cmdline-tools/latest/bin:/opt/android-sdk-linux/platform-tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && curl -Lo sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip \
    && unzip sdk.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm sdk.zip

# 安装 Android 平台工具 & 构建工具
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
    && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
       "platform-tools" \
       "platforms;android-34" \
       "build-tools;34.0.0"

# 创建缓存目录并授权
RUN mkdir -p /.android /.gradle \
    && chown -R jenkins:jenkins ${ANDROID_HOME} /.android /.gradle

USER jenkins

# 可选：预安装 Jenkins 插件
RUN jenkins-plugin-cli --plugins git gradle android-emulator ws-cleanup embeddable-build-status blueocean locale ssh-steps pipeline-utility-steps pipeline-maven pipeline-maven-api okhttp-api pipeline-model-api pipeline-model-definition pipeline-model-extensions workflow-durable-task-step

