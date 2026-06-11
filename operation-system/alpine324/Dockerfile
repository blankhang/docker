FROM alpine:3.24
ARG TARGETARCH
LABEL maintainer="blankhang <blankhang@gmail.com>"
RUN apk add --no-cache ca-certificates bash curl openssl zip zstd tzdata tar fontconfig font-dejavu font-wqy-zenhei \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && case "${TARGETARCH:-amd64}" in \
        amd64) \
            apk add --no-cache binutils \
            && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
            && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk \
            && apk add --force-overwrite glibc-2.35-r1.apk \
            && curl -Ls https://www.archlinux.org/packages/core/x86_64/gcc-libs/download > /tmp/gcc-libs.tar.zst \
            && mkdir /tmp/gcc \
            && zstd -d /tmp/gcc-libs.tar.zst \
            && tar xvf /tmp/gcc-libs.tar -C /tmp/gcc \
            && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
            && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
            && curl -Ls https://www.archlinux.org/packages/core/x86_64/zlib/download > /tmp/libz.tar.zst \
            && mkdir /tmp/libz \
            && tar -xf /tmp/libz.tar.zst -C /tmp/libz \
            && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
            && apk del binutils \
            && rm -rf glibc-2.35-r1.apk /tmp/gcc /tmp/gcc-libs.tar.zst /tmp/gcc-libs.tar /tmp/libz /tmp/libz.tar.zst \
            ;; \
        arm64) \
            echo "arm64: skip sgerrand glibc (x86_64 only), musl base only" \
            ;; \
        *) echo "unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac \
    && rm -rf /var/cache/apk/*

ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8
