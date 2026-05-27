# nginx-geoip2

基于你 fork 的 `blankhang/geoip2` 构建 Nginx 动态模块 `ngx_http_geoip2_module.so`，用于从 MaxMind GeoIP2 数据库中读取国家、城市、经纬度等信息；上游来源仍然是 `leev/ngx_http_geoip2_module`。[fork 地址](https://github.com/blankhang/geoip2)

## 本地构建

```shell
export DOCKER_BUILDKIT=1

# 导出 .so
docker build \
  --build-arg NGINX_VERSION=1.28.1 \
  --target export \
  -o type=local,dest=./out .

# 构建可运行镜像
docker build \
  --build-arg NGINX_VERSION=1.28.1 \
  --target final \
  -t blankhang/nginx-geoip2:1.28.1 .
```

生成的模块文件位于 `./out/ngx_http_geoip2_module.so`。

## GitHub Actions 自动构建

已新增工作流 `/.github/workflows/docker-image-nginx-geoip2.yml`，支持：

1. 定时轮询 nginx 官方稳定版
2. 手动指定 nginx 版本触发构建

工作流会执行以下动作：

- 检测目标 nginx 版本是否存在
- 构建并推送 `blankhang/nginx-geoip2:<version>`
- 同步推送阿里云镜像仓库
- 构建阶段固定从 `https://github.com/blankhang/geoip2.git` 拉取指定 `GEOIP2_REF`
- 在 `blankhang/geoip2` 的 Release 中上传 `amd64` / `arm64` 两套 `.so` 与 `.sha256`
- 如果镜像已存在但 Release 缺失，会直接从镜像提取模块补发 Release

跨仓库发布 Release 需要在当前仓库配置 secret：

- `GEOIP2_RELEASE_TOKEN`: 对目标仓库 `blankhang/geoip2` 具备 `contents: write` 权限的 token

## nginx.conf 示例

根据 `ngx_http_geoip2_module` 文档，先在 `nginx.conf` 第一行加载动态模块：[README](https://github.com/leev/ngx_http_geoip2_module)

```nginx
load_module /etc/nginx/modules/ngx_http_geoip2_module.so;

http {
    geoip2 /etc/nginx/geoip2/GeoLite2-City.mmdb {
        auto_reload 5m;
        $geoip2_data_country_code default=US source=$remote_addr country iso_code;
        $geoip2_data_country_name country names en;
        $geoip2_data_city_name city names en;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            add_header X-Country-Code $geoip2_data_country_code;
            add_header X-Country-Name $geoip2_data_country_name;
            add_header X-City-Name $geoip2_data_city_name;
            return 200 "geoip2 enabled\n";
        }
    }
}
```

如果你的请求经过反向代理或 Cloudflare，可以改用 `source=$http_cf_connecting_ip` 或其他真实来源 IP 变量。这一点在社区文章里也有示例说明。[参考文章](https://www.azio.me/how-to-install-ngx_http_geoip2_module/)

## 部署说明

1. 把 `ngx_http_geoip2_module.so` 放到 Nginx 模块目录，例如 `/etc/nginx/modules/`
2. 把 GeoIP2 数据库文件放到 `/etc/nginx/geoip2/`
3. 执行配置校验并重载：

```shell
nginx -t && nginx -s reload
```