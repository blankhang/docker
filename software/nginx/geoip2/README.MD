# nginx-geoip2

## build

```shell
$ cd /usr/local/src
$ wget https://nginx.org/download/nginx-1.28.1.tar.gz
$ tar -zxf nginx-1.28.1.tar.gz && rm -rf nginx-1.28.1.tar.gz
$ git clone https://github.com/lionsoul2014/ip2region.git
$ cd ip2region/binding/c
$ make xdb_searcher_lib
$ cd ../../../nginx-1.28.1
$ ./configure \
  --with-compat \
  --add-dynamic-module=$(pwd)/../ip2region/binding/nginx \
  --with-cc-opt="-I $(pwd)/../ip2region/binding/c/build/include" \
  --with-ld-opt="-L$(pwd)/../ip2region/binding/c/build/lib"
$ make
$ make install
```

## 利用 docker 构建动态模块

```shell
export DOCKER_BUILDKIT=1

# 1. 构建最终 nginx 镜像
#docker build --build-arg NGINX_VERSION=1.28.1 -t custom-nginx:1.28.1 .

# 2. 只导出 so 文件到当前目录 tar 包
docker build --build-arg NGINX_VERSION=1.28.1 --target build -o type=tar,dest=./ngx_http_geoip2_module.tar .

tar xf ngx_http_geoip2_module.tar

```

## nginx conf

> Syntax:  `ip2region_db xdb_file_path [cache_policy Optional]`;
> Context: http

cache_policy: `file` or `vectorIndex` or `content`, default: `content`

Edit `nginx.conf` add `ip2region_db` directive

```nginx

... 

# 如果是动态模块需要使用 load_module 的方式来加载它 需要放在 nginx.conf 第一行
# load_module /etc/nginx/modules/ngx_http_ip2region_module.so;

http {

    log_format main escape=json '{'
                    '"time": "$time_local", '
                    '"remote_addr": "$remote_addr", '
                    '"region": "$ip2region", '
                    '"method": "$request_method", '
                    '"uri": "$request_uri", '
                    '"status": "$status", '
                    '"body_bytes_sent": "$body_bytes_sent", '
                    '"referer": "$http_referer", '
                    '"user_agent": "$http_user_agent", '
                    '"http_x_forwarded_for": "$http_x_forwarded_for"'
    '}';

    access_log logs/access.log main;

    # set xdb file path
    ip2region_db ip2region.xdb;
    # ip2region_db ip2region.xdb vectorIndex;
    # ip2region_db ip2region.xdb file;
    # ip2region_db ip2region.xdb content;

    server {
        listen 80;
        server_name localhost;

        location / {
            root html;
            index index.html index.htm;
        }
    }
}

```
Copy `ngx_http_ip2region_module.so` to `/etc/nginx/modules` folder  
Copy `ip2region.xdb` to `/etc/nginx` folder, then reload nginx

```shell
nginx -s reload
```

nginx access log sample

```log
{"time": "28/May/2025:14:32:55 +0800", "remote_addr": "183.11.242.141", "region": "中国|0|广东省|深圳市|电信", "method": "GET", "uri": "/", "status": "200", "body_bytes_sent": "798", "referer": "https://xxx.com/index", "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36", "http_x_forwarded_for": ""}

```
thanks fa1seut0pia for https://github.com/lionsoul2014/ip2region/pull/359