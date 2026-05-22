# ---------- ARG ----------
ARG NGINX_VERSION=1.28.1

# ---------- 第一阶段：构建动态模块 ----------
FROM nginx:${NGINX_VERSION} AS build

RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# 下载 nginx 源码
RUN curl -fsSLO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION}.tar.gz

# 克隆 ip2region db2.0-final
RUN git clone https://github.com/lionsoul2014/ip2region.git \
    && cd ip2region \
    && git checkout v20250906-db2.0-final

# 编译 C binding
WORKDIR /usr/src/ip2region/binding/c
RUN make xdb_searcher_lib

# 构建 nginx 动态模块
WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN ./configure \
    --with-compat \
    --add-dynamic-module=/usr/src/ip2region/binding/nginx \
    --with-cc-opt="-I/usr/src/ip2region/binding/c/build/include" \
    --with-ld-opt="-L/usr/src/ip2region/binding/c/build/lib"

RUN make modules

# ---------- 第二阶段：导出 .so ----------
FROM scratch AS export
ARG NGINX_VERSION
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_ip2region_module.so /

# ---------- 第三阶段：可运行 nginx 镜像 ----------
FROM nginx:${NGINX_VERSION} AS final

# 创建 nginx 模块目录（官方镜像里可能已存在）
RUN mkdir -p /etc/nginx/modules/

# 拷贝动态模块
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_ip2region_module.so /etc/nginx/modules/

# 默认启动 nginx
CMD ["nginx", "-g", "daemon off;"]


#使用方式
# 1 导出 .so
#```shell
#export DOCKER_BUILDKIT=1
#docker build --target export -o type=local,dest=./out .
# ./out/ngx_http_ip2region_module.so 就在当前目录
#```
# 2 构建可运行的 nginx 镜像
#```shell
#export DOCKER_BUILDKIT=1
#docker build --target final -o type=local,dest=./out .
#```