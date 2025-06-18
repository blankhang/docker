# https://github.com/jenkinsci/docker/blob/master/README.md
FROM jenkins/jenkins:lts-jdk21
MAINTAINER blankhang@gmail.com

USER root

ENV GRADLE_VERSION=7.6.3
ENV GRADLE_USER_HOME /.gradle
ENV GRADLE_HOME=/opt/gradle

ENV ANDROID_HOME=/usr/lib/android-sdk/

# install docker cli
RUN apt -y update; apt install -y sudo; apt install -y --no-install-recommends git wget \
  && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers \
  && wget http://get.docker.com/builds/Linux/x86_64/docker-latest.tgz \
  && tar -xvzf docker-latest.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -rf docker docker-latest.tgz \
  && rm -rf /var/lib/apt/lists/*

# install chinese language support and maven nodejs npm yarn pnpm
RUN apt update && apt install -y --no-install-recommends locales fontconfig maven nodejs npm \
    && echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen zh_CN.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn pnpm


#./sdkmanager --licenses --sdk_root=/home/jenkins/Android/android-sdk-linux/

## install gradle
#RUN set -o errexit -o nounset \
#	&& echo "Downloading Gradle" \
#	&& curl -Lo gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
#	&& echo "Installing Gradle" \
#	&& unzip gradle.zip \
#	&& rm gradle.zip \
#	&& mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
#	&& ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
#	&& echo "Testing Gradle installation" \
#	&& gradle --version

# .gradle and .android are a cache folders
RUN mkdir -p ${GRADLE_USER_HOME}/caches /.android  \
	&& chmod -R 777 ${GRADLE_USER_HOME} \
	&& chmod 777 /.android


# Setting Default Chinese Language and UTC+8 timezone
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8
ENV TZ Asia/Shanghai

USER jenkins