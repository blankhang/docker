# 指定 Nginx 版本
ARG NGINX_VERSION=1.28.1
FROM nginx:${NGINX_VERSION} AS build

# 安装编译依赖
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

# 下载 Nginx 源码
RUN curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxf nginx-${NGINX_VERSION}.tar.gz

# 下载 ngx_http_geoip2_module
RUN git clone --depth=1 https://github.com/leev/ngx_http_geoip2_module.git

# 配置 Nginx 编译参数（动态模块）
WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN ./configure --with-compat \
    --add-dynamic-module=/usr/src/ngx_http_geoip2_module \
    --with-cc-opt="-I/usr/include/libmaxminddb" \
    --with-ld-opt="-L/usr/lib"

# 编译动态模块
RUN make modules

# 最终镜像
FROM nginx:${NGINX_VERSION}

# 拷贝动态模块到 nginx 模块目录
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /etc/nginx/modules/

# 创建 GeoIP2 数据目录
RUN mkdir -p /etc/nginx/geoip2

# 默认启动 nginx
CMD ["nginx", "-g", "daemon off;"]
