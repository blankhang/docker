# nginx-ip-bundle

同时包含以下两个 Nginx 动态模块：

- `ngx_http_ip2region_module.so`
- `ngx_http_geoip2_module.so`

适合希望一次镜像交付两个 IP 相关插件的场景。

## 本地构建

```shell
export DOCKER_BUILDKIT=1

# 导出两个 .so
docker build \
  --build-arg NGINX_VERSION=1.30.2 \
  --target export \
  -o type=local,dest=./out .

# 构建可运行镜像
docker build \
  --build-arg NGINX_VERSION=1.30.2 \
  --target final \
  -t blankhang/nginx-ip-bundle:1.30.2 .
```

构建完成后，`./out` 目录下会包含：

- `ngx_http_ip2region_module.so`
- `ngx_http_geoip2_module.so`

## GitHub Actions 自动构建

工作流 `/.github/workflows/docker-image-nginx-ip-bundle.yml` 会：

- 构建并推送 `blankhang/nginx-ip-bundle:<version>`
- 为 `amd64` / `arm64` 两个架构分别导出包含两个模块的发布包
- 在当前仓库 Release 中上传 bundle 资产与对应 `sha256`

## nginx.conf 示例

```nginx
load_module /etc/nginx/modules/ngx_http_ip2region_module.so;
load_module /etc/nginx/modules/ngx_http_geoip2_module.so;

http {
    ip2region_db /etc/nginx/ip2region/ip2region.xdb;

    geoip2 /etc/nginx/geoip2/GeoLite2-City.mmdb {
        auto_reload 5m;
        $geoip2_data_country_code default=US source=$remote_addr country iso_code;
        $geoip2_data_country_name country names en;
    }
}
```

## 部署说明

1. 将两个 `.so` 放入 `/etc/nginx/modules/`
2. 准备 `ip2region.xdb` 与 GeoIP2 `.mmdb` 数据文件
3. 执行：

```shell
nginx -t && nginx -s reload
```
