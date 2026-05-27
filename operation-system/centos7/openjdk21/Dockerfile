FROM blankhang/centos7
LABEL maintainer="blankhang <blankhang@gmail.comm>"
LABEL version='1.0' description='centos7 with chinese lanugage and openjdk17 and CST GMT+8 timezone support'

ARG TARGETARCH

RUN yum install -y kde-l10n-Chinese glibc-common \
    &&  case ${TARGETARCH} in \
            "amd64")  OS_ARCH=x64  ;; \
            "arm64")  OS_ARCH=aarch64  ;; \
        esac \
    && rpm -i https://download.oracle.com/java/21/latest/jdk-21_linux-${OS_ARCH}_bin.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum/* \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
    && echo "Asia/Shanghai" > /etc/timezone \
    && echo "LANG=zh_CN.UTF-8" >> /etc/locale.conf

ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8
