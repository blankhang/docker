# ---------- ARG ----------
ARG NGINX_VERSION=1.28.1
ARG IP2REGION_REPO=https://github.com/blankhang/ip2region.git
ARG IP2REGION_REF=fac3d0376a7c75307104ac4fc65b945020f6cca2
ARG GEOIP2_REPO=https://github.com/blankhang/geoip2.git
ARG GEOIP2_REF=cbaa35461c62a99d2577e6bae3273492502d8769

# ---------- 第一阶段：构建动态模块 ----------
FROM nginx:${NGINX_VERSION} AS build

ARG IP2REGION_REPO
ARG IP2REGION_REF
ARG GEOIP2_REPO
ARG GEOIP2_REF

RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    git \
    curl \
    libmaxminddb-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

RUN curl -fsSLO https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxf nginx-${NGINX_VERSION}.tar.gz

RUN git init ip2region \
    && cd ip2region \
    && git remote add origin "${IP2REGION_REPO}" \
    && git fetch --depth 1 origin "${IP2REGION_REF}" \
    && git checkout --detach FETCH_HEAD \
    && test -d binding/c \
    && test -d binding/nginx

RUN git init ngx_http_geoip2_module \
    && cd ngx_http_geoip2_module \
    && git remote add origin "${GEOIP2_REPO}" \
    && git fetch --depth 1 origin "${GEOIP2_REF}" \
    && git checkout --detach FETCH_HEAD \
    && test -f config \
    && test -f ngx_http_geoip2_module.c

WORKDIR /usr/src/ip2region/binding/c
RUN make xdb_searcher_lib

WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN ./configure \
    --with-compat \
    --add-dynamic-module=/usr/src/ip2region/binding/nginx \
    --add-dynamic-module=/usr/src/ngx_http_geoip2_module \
    --with-cc-opt="-I/usr/src/ip2region/binding/c/build/include -I/usr/include/libmaxminddb" \
    --with-ld-opt="-L/usr/src/ip2region/binding/c/build/lib -L/usr/lib"

RUN make modules

# ---------- 第二阶段：导出 .so ----------
FROM scratch AS export
ARG NGINX_VERSION
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_ip2region_module.so /
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /

# ---------- 第三阶段：可运行 nginx 镜像 ----------
FROM nginx:${NGINX_VERSION} AS final

RUN apt-get update && apt-get install -y \
    libmaxminddb0 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/modules/ /etc/nginx/geoip2 /etc/nginx/ip2region
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_ip2region_module.so /etc/nginx/modules/
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /etc/nginx/modules/

CMD ["nginx", "-g", "daemon off;"]
