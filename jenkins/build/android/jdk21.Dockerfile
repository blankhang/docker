## Based Image
FROM jenkins/jenkins:lts-jdk21

## Thanks to https://github.com/WindSekirun/Jenkins-Android-Docker/blob/master/Dockerfile

## Define Environment
LABEL maintainer="blankhang@gmail.com"

ENV ANDROID_SDK_ZIP commandlinetools-linux-10406996_latest.zip
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/repository/$ANDROID_SDK_ZIP
ENV ANDROID_PLATFORM_ZIP platform-tools_r34.0.4-linux.zip
ENV ANDROID_PLATFORM_ZIP_URL https://dl.google.com/android/repository/$ANDROID_PLATFORM_ZIP

ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_ROOT /opt/android-sdk-linux

ENV GRADLE_ZIP gradle-8.5-bin.zip
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/$GRADLE_ZIP

ENV PATH $PATH:$ANDROID_SDK_ROOT/cmdline-tools/bin
ENV PATH $PATH:$ANDROID_SDK_ROOT/platform-tools/bin
ENV PATH $PATH:/opt/gradle-8.5/bin

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
          org.label-schema.name="Jenkins-Android-Docker" \
          org.label-schema.description="Docker image for Jenkins with Android and maven nodejs npm yarn pnpm and GMT+08 setting " \
          org.label-schema.vcs-ref=$VCS_REF \
          org.label-schema.vcs-url="https://github.com/blankhang/docker/jenkins" \
          org.label-schema.vendor="blankhang" \
          org.label-schema.version=$VERSION \
          org.label-schema.schema-version="1.0"

USER root

# Setting UTC+8 timezone
ENV TZ Asia/Shanghai

RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# install chinese language support and maven nodejs npm yarn pnpm
RUN apt update && apt install -y --no-install-recommends locales fontconfig maven nodejs npm \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen zh_CN.UTF-8 \
    && npm install -g yarn pnpm

## Install requirements
RUN dpkg --add-architecture i386
RUN rm -rf /var/lib/apt/list/* && apt-get update && apt-get install ca-certificates curl gnupg2 software-properties-common git unzip file apt-utils lxc apt-transport-https libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

## Install Docker-ce into Image
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "${ID}")/gpg > /tmp/dkey;
RUN apt-key add /tmp/dkey
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "${ID}") $(lsb_release -cs) stable"
RUN apt-get update && apt-get install docker-ce -y --no-install-recommends && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
RUN usermod -a -G docker jenkins

## Install Android SDK into Image
ADD $GRADLE_ZIP_URL /opt/
RUN unzip /opt/$GRADLE_ZIP -d /opt/ && rm /opt/$GRADLE_ZIP

ADD $ANDROID_SDK_ZIP_URL /opt/
RUN unzip -q /opt/$ANDROID_SDK_ZIP -d $ANDROID_SDK_ROOT && rm /opt/$ANDROID_SDK_ZIP

ADD $ANDROID_PLATFORM_ZIP_URL /opt/
RUN unzip -q /opt/$ANDROID_PLATFORM_ZIP -d $ANDROID_SDK_ROOT && rm /opt/$ANDROID_PLATFORM_ZIP

RUN echo "$PATH"

RUN echo yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "build-tools;34.0.0"
RUN echo yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-34"

RUN chown -R jenkins "$ANDROID_SDK_ROOT"

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

## Install Jenkins plugin
USER jenkins

RUN jenkins-plugin-cli --plugins git gradle android-emulator ws-cleanup embeddable-build-status blueocean locale ssh-steps pipeline-utility-steps pipeline-maven pipeline-maven-api okhttp-api pipeline-model-api pipeline-model-definition pipeline-model-extensions workflow-durable-task-step

