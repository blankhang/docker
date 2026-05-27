# ---------- ARG ----------
ARG NGINX_VERSION=1.28.1
ARG GEOIP2_REPO=https://github.com/blankhang/geoip2.git
ARG GEOIP2_REF=cbaa35461c62a99d2577e6bae3273492502d8769

# ---------- 第一阶段：构建动态模块 ----------
FROM nginx:${NGINX_VERSION} AS build

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

RUN git init ngx_http_geoip2_module \
    && cd ngx_http_geoip2_module \
    && git remote add origin "${GEOIP2_REPO}" \
    && git fetch --depth 1 origin "${GEOIP2_REF}" \
    && git checkout --detach FETCH_HEAD \
    && test -f config \
    && test -f ngx_http_geoip2_module.c

WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN ./configure --with-compat \
    --add-dynamic-module=/usr/src/ngx_http_geoip2_module \
    --with-cc-opt="-I/usr/include/libmaxminddb" \
    --with-ld-opt="-L/usr/lib"

RUN make modules

# ---------- 第二阶段：导出 .so ----------
FROM scratch AS export
ARG NGINX_VERSION
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /

# ---------- 第三阶段：可运行 nginx 镜像 ----------
FROM nginx:${NGINX_VERSION} AS final

RUN apt-get update && apt-get install -y \
    libmaxminddb0 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/modules/ /etc/nginx/geoip2
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /etc/nginx/modules/
CMD ["nginx", "-g", "daemon off;"]
