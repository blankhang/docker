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
            && curl -Ls https://www.archlinux.org/packages/core/x86_64/libgcc/download > /tmp/libgcc.tar.zst \
            && mkdir -p /tmp/libgcc \
            && zstd -d /tmp/libgcc.tar.zst -o /tmp/libgcc.tar \
            && tar xf /tmp/libgcc.tar -C /tmp/libgcc \
            && mv /tmp/libgcc/usr/lib/libgcc_s.so* /usr/glibc-compat/lib/ \
            && curl -Ls https://www.archlinux.org/packages/core/x86_64/libstdc++/download > /tmp/libstdc++.tar.zst \
            && mkdir -p /tmp/libstdcpp \
            && zstd -d /tmp/libstdc++.tar.zst -o /tmp/libstdc++.tar \
            && tar xf /tmp/libstdc++.tar -C /tmp/libstdcpp \
            && mv /tmp/libstdcpp/usr/lib/libstdc++.so* /usr/glibc-compat/lib/ \
            && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
            && curl -Ls https://www.archlinux.org/packages/core/x86_64/zlib/download > /tmp/libz.tar.zst \
            && mkdir -p /tmp/libz \
            && zstd -d /tmp/libz.tar.zst -o /tmp/libz.tar \
            && tar xf /tmp/libz.tar -C /tmp/libz \
            && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib/ \
            && apk del binutils \
            && rm -rf glibc-2.35-r1.apk /tmp/libgcc /tmp/libgcc.tar* /tmp/libstdcpp /tmp/libstdc++.tar* /tmp/libz /tmp/libz.tar* \
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
