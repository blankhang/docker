# nginx-ip2region

## build

```shell
$ mkdir -p workspace
$ cd workspace
$ wget https://nginx.org/download/nginx-1.28.0.tar.gz
$ tar -zxf nginx-1.28.0.tar.gz && rm -rf nginx-1.28.0.tar.gz
$ git clone https://github.com/lionsoul2014/ip2region.git
$ cd ip2region/binding/c
$ make xdb_searcher_lib
$ cd ../../../nginx-1.28.0
$ ./configure                                                            \
    --add-module=$(PWD)/../ip2region/binding/nginx                       \
    --with-cc-opt="-I $(PWD)/../ip2region/binding/c/build/include"       \
    --with-ld-opt="-L$(PWD)/../ip2region/binding/c/build/lib"
$ make
$ make install
```

## 利用 docker 构建动态模块

```shell
# 启用 BuildKit
export DOCKER_BUILDKIT=1

# 构建一个包含ip2region的动态模块自定义镜像, 默认版本由参数 `ARG NGINX_VERSION=1.27.0` 控制
docker build -t custom-nginx .

# 构建一个包含ip2region的动态模块自定义镜像, 且指定nginx版本 
docker build -t custom-nginx:1.26.1 --build-arg NGINX_VERSION=1.26.1 .

# 导出动态模块到当前目录, target表示目标阶段, o是output 输出类型和位置
docker build --target export_so -o type=tar,dest=./so.tar .
# 解压即可看到 `ngx_http_ip2region_module.so`, 可将此模块放置到nginx的模块目录,比如 /etc/nginx/modules/
tar xf so.tar 

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