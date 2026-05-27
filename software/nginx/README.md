# docker nginx

### 所有文件将会创建到 /docker/nginx 目录中
### 如果是aliyun服务器 域名 
### 可利用 Ali_Key Ali_Secret 使用 application-ssl-certs.sh 来申请 Let's Encrypt's 的免费证书
```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh application-ssl-certs.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 redis-stack.yml  conf.d log ssl
sh init.sh


# 强烈建议不直接修改 目录中的主配置文件 nginx.conf 
# 而是将不同子域名 按类似 sub.yourdamon.conf 放置在 /docker/nginx/conf.d 目录中

# 启动 nginx
sh start.sh
# 或
docker-compose -f /docker/nginx/redis-stack.yml up -d
# 修改配置文件后 

# 检查配置文件是否正确
docker exec -it nginx nginx -t

# 配置文件正确即可重启nginx
# 重新启动 nginx
docker exec -it nginx service nginx restart

# 或
docker-compose -f /docker/nginx/redis-stack.yml restart

# 停止 nginx
docker-compose -f /docker/nginx/redis-stack.yml down
```

### 自动更新 geoip2 / ip2region 模块

如果你的 Nginx 是宿主机安装版，并且动态模块文件放在 `/docker/nginx/ip`，可以使用 `update-ip-modules.sh`：

```shell
chmod 755 update-ip-modules.sh
# 先按 apply_cert.sh 的方式修改脚本顶部配置
./update-ip-modules.sh install
```

脚本会自动完成这些动作：

- 根据当前机器架构识别 `amd64` 或 `arm64`
- 从 `blankhang/geoip2` 与 `blankhang/ip2region` 的 Release 中，选择两边都存在的**同一 nginx 版本**最新模块
- 下载对应 `.so` 到 `/docker/nginx/ip`
- 对脚本同目录 `ip/GeoLite2-City.mmdb` 与 `ip/ip2region_v4.xdb` 做大小对比，缺失或大小不一致时自动同步数据库文件
- 统一以 `software/nginx/nginx.conf` 作为基准模板生成本机和远端的最终 `nginx.conf`
- 自动改写最终 `nginx.conf` 顶部的 `load_module` 行
- 先执行 `nginx -t`，通过后再覆盖配置；应用配置时优先 `systemctl reload nginx`，必要时回退 `systemctl restart nginx`，最后才兜底 `nginx -s reload`
- 如果 `restart` 因旧 `nginx` 残留进程仍占用 80/443 而失败，脚本会尝试清理残留监听进程后再重试一次
- 如果配置了 `REMOTE_HOSTS`，还会逐台检测远端架构、逐台选择对应架构插件，并生成远端专属的 `nginx.conf`
- 如果远端 `nginx` 版本低于插件要求，会先看远端软件源当前“能升级到的候选版本”
- 只有当该候选版本也存在**完全匹配**的双模块 Release 时，才会升级远端 `nginx` 并切换配置
- 如果某台远端刚升级过 `nginx`，脚本会优先对该机器执行 `systemctl restart nginx`，避免 PID 文件尚未稳定时直接 `nginx -s reload` 报错
- 如果软件源暂时拿不到带匹配插件的版本，脚本只会先下载新插件文件，不改远端 `nginx.conf`、不执行 reload
- 对于之前手工 `apt-mark hold nginx` / `nginx-*` 的机器，脚本会临时解除 hold、升级完成后再恢复 hold

如果你是容器内执行 `nginx -t` / reload，也可以自定义命令：

```shell
NGINX_TEST_CMD='docker exec nginx nginx -t -c __CONF__' \
NGINX_RELOAD_CMD='docker exec nginx nginx -s reload' \
./update-ip-modules.sh install
```

`update-ip-modules.sh` 已经按 `apply_cert.sh` 的风格实现，建议直接在脚本顶部维护这些配置：

- `TEMPLATE_NGINX_CONF`
- `SOURCE_DB_DIR`
- `SYNC_IP_DATABASES=true`
- `LOCAL_MODULE_DIR`
- `LOCAL_NGINX_CONF`
- `REMOTE_MODULE_DIR`
- `REMOTE_NGINX_CONF`
- `REMOTE_HOSTS=("wh-1" "wh-2" ...)`

如果你以后要调整 GeoIP2、ip2region 或整体基础配置，直接修改 `software/nginx/nginx.conf` 即可；后续执行 `install` / `sync` / `all` 时，会基于这一个模板统一生成并同步到目标机器。

如果你要更新 IP 数据库文件，也只需要维护脚本同目录的这两个文件：

- `software/nginx/ip/GeoLite2-City.mmdb`
- `software/nginx/ip/ip2region_v4.xdb`

脚本会在本机和远端都检查它们是否缺失或大小不一致，必要时自动覆盖同步。
如果你暂时不想同步数据库文件，把脚本顶部的 `SYNC_IP_DATABASES` 改成 `false` 即可。

如果你想按 `apply_cert.sh` 的风格直接做远端同步，可以这样：

```shell
./update-ip-modules.sh all
```

对应模式：

- `install`：只更新本机模块和本机 `nginx.conf`
- `sync`：逐台按远端架构/远端版本生成并同步对应文件
- `all`：先本机更新，再远端同步

默认内置的远端升级逻辑会优先尝试使用 Nginx 官方 `mainline` 软件源；如果你的机器环境比较特殊，也可以通过 `REMOTE_NGINX_UPGRADE_CMD` 自定义升级命令。该命令支持 `__TARGET_VERSION__` 占位符。

这意味着像“远端软件源当前只有 `1.30.1`，但你最新插件是 `1.31.1`”这种情况，脚本不会强行把远端配置切到 `1.31.1`；它会先保持远端继续跑旧插件版本，等下次远端源能升到有匹配插件的版本时再切换。

---
#### CentOS 7 安装 nginx
```shell script
#### 安装 nginx 官方 rpm 源
rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
#### 安装 官方 nginx
yum install  -y nginx
```