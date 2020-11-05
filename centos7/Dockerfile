FROM centos:7
MAINTAINER blankhang <blankhang@gmail.com>
LABEL version='1.0' description='centos7 with chinese lanugage and CST GMT+8 timezone support'

RUN yum update -y && \
yum install -y libXmu freetype kde-l10n-Chinese cabextract xorg-x11-font-utils fontconfig && \
rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm && \
yum -y reinstall glibc-common && \
yum groupinstall "fonts" -y && \
mkfontscale && \
#mkfontdir && \
fc-cache -fv && \
localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 && \
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
echo "Asia/Shanghai" > /etc/timezone && \
yum clean all && \
rm -rf /var/cache/yum/*

ENV TZ Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8