FROM blankhang/centos7
LABEL maintainer="blankhang <blankhang@gmail.comm>"
LABEL version='1.0' description='centos7 with chinese lanugage and openjdk8 and CST GMT+8 timezone support'

#COPY ./msyh.ttf /usr/share/fonts/msyh.ttf

RUN yum install -y libXmu freetype kde-l10n-Chinese fontconfig && \
yum -y reinstall glibc-common && \
yum groupinstall "fonts" -y && \
fc-cache -fv && \
localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 && \
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
echo "Asia/Shanghai" > /etc/timezone && \
yum install -y java-1.8.0-openjdk && \
yum clean all && \
rm -rf /var/cache/yum/*

ENV TZ Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8