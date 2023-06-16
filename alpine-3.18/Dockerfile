FROM alpine:3.18
MAINTAINER blankhang <blankhang@gmail.comm>
RUN apk add --no-cache ca-certificates bash curl openssl binutils zip zstd tzdata tar \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk \
    && apk add glibc-2.35-r1.apk \
    && echo 'add glibc 2.35-r1 finish' \
    && curl -Ls https://www.archlinux.org/packages/core/x86_64/gcc-libs/download > /tmp/gcc-libs.tar.zst \
    && mkdir /tmp/gcc \
    && echo 'mkdir /tmp/gcc ' \
    && zstd -d /tmp/gcc-libs.tar.zst  \
    && echo 'zstd -d /tmp/gcc-libs.tar.zst' \
    && tar xvf /tmp/gcc-libs.tar -C /tmp/gcc \
    && echo 'tar xvf /tmp/gcc-libs.tar -C /tmp/gcc' \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && echo 'mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib' \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
    && echo 'strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so*' \
    && curl -Ls https://www.archlinux.org/packages/core/x86_64/zlib/download > /tmp/libz.tar.zst \
    && echo 'curl -Ls https://www.archlinux.org/packages/core/x86_64/zlib/download' \
    && mkdir /tmp/libz \
    && echo 'mkdir /tmp/libz' \
    && tar -xf /tmp/libz.tar.zst -C /tmp/libz \
    && echo 'tar -xf /tmp/libz.tar.zst -C /tmp/libz' \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
    && echo 'mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib' \
    && apk del binutils \
    && echo 'apk del binutils' \
    && rm -rf glibc-2.35-r1.apk /tmp/gcc /tmp/gcc-libs.tar.zst /tmp/libz /tmp/libz.tar.zst /var/cache/apk/* \
    && echo 'rm -rf glibc-2.35-r1.apk /tmp/gcc /tmp/gcc-libs.tar.zst /tmp/libz /tmp/libz.tar.zst /var/cache/apk/*'
