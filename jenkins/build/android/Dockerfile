## Based Image
FROM jenkins/jenkins:lts-jdk17

## Define Environment
LABEL maintainer="blankhang@gmail.com"

ENV ANDROID_SDK_ZIP commandlinetools-linux-10406996_latest.zip
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/repository/$ANDROID_SDK_ZIP
ENV ANDROID_PLATFORM_ZIP platform-tools_r34.0.4-linux.zip
ENV ANDROID_PLATFORM_ZIP_URL https://dl.google.com/android/repository/$ANDROID_PLATFORM_ZIP

ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_ROOT /opt/android-sdk-linux

ENV GRADLE_ZIP gradle-7.6.3-bin.zip
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/$GRADLE_ZIP

ENV PATH $PATH:$ANDROID_SDK_ROOT/tools/bin
ENV PATH $PATH:$ANDROID_SDK_ROOT/platform-tools
ENV PATH $PATH:/opt/gradle-7.6.3/bin

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
          org.label-schema.name="Jenkins-Android-Docker" \
          org.label-schema.description="Docker image for Jenkins with Android " \
          org.label-schema.vcs-ref=$VCS_REF \
          org.label-schema.vcs-url="https://github.com/blankhang/docker/jenkins" \
          org.label-schema.vendor="blankhang" \
          org.label-schema.version=$VERSION \
          org.label-schema.schema-version="1.0"

USER root

# install chinese language support and maven nodejs npm yarn pnpm
RUN apt update && apt install -y --no-install-recommends locales fontconfig maven nodejs npm \
    && echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen zh_CN.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn pnpm

## Install requirements
RUN dpkg --add-architecture i386
RUN rm -rf /var/lib/apt/list/* && apt-get update && apt-get install ca-certificates curl gnupg2 software-properties-common git unzip file apt-utils lxc apt-transport-https libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y

## Install Docker-ce into Image
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey;
RUN apt-key add /tmp/dkey
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
RUN apt-get update && apt-get install docker-ce -y --no-install-recommends
RUN usermod -a -G docker jenkins

## Install Android SDK into Image
ADD $GRADLE_ZIP_URL /opt/
RUN unzip /opt/$GRADLE_ZIP -d /opt/ && rm /opt/$GRADLE_ZIP

ADD $ANDROID_SDK_ZIP_URL /opt/
RUN unzip -q /opt/$ANDROID_SDK_ZIP -d $ANDROID_SDK_ROOT && rm /opt/$ANDROID_SDK_ZIP

ADD $ANDROID_PLATFORM_ZIP_URL /opt/
RUN unzip -q /opt/$ANDROID_PLATFORM_ZIP -d $ANDROID_SDK_ROOT && rm /opt/$ANDROID_PLATFORM_ZIP

RUN echo "$path"

RUN echo yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "build-tools;34.0.0"
RUN echo yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-34"
RUN echo yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "build-tools;33.0.2"
RUN echo yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-33"

RUN chown -R jenkins $ANDROID_SDK_ROOT

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Install Jenkins plugin
USER jenkins

RUN /usr/local/bin/install-plugins.sh git gradle android-emulator ws-cleanup slack embeddable-build-status blueocean github-coverage-reporter jacoco github-pr-coverage-status locale