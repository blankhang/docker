FROM alpine:3.12
LABEL maintainer="blankhang <blankhang@gmail.comm>"
# Install required packages
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    openssl \
    binutils \
    zip \
    zstd \
    tzdata

# Set timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# Install glibc (consider alternative methods if needed)
ENV GLIBC_VER="2.32-r0"
ENV ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"
RUN curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/${GLIBC_VER}.apk \
    && apk add --allow-untrusted /tmp/${GLIBC_VER}.apk \
    && rm -f /tmp/${GLIBC_VER}.apk

# Cleanup
RUN apk del binutils \
    && rm -rf /var/cache/apk/*