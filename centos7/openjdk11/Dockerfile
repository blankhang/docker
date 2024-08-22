FROM blankhang/centos7
LABEL maintainer="blankhang <blankhang@gmail.comm>"
LABEL version='1.0' description='centos7 with chinese lanugage and openjdk11 and CST GMT+8 timezone support'

RUN yum install -y kde-l10n-Chinese glibc-common java-11-openjdk && \
yum clean all && \
rm -rf /var/cache/yum/* && \
localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 && \
echo "Asia/Shanghai" > /etc/timezone && \
echo "LANG=zh_CN.UTF-8" >> /etc/locale.conf

ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8
