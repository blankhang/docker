# docker redis 8

默认示例密码见 [.env.example](.env.example)（`REDIS_PASSWORD=changeme`，生产务必修改）。

## Swarm 1 主 2 从

见 [docker-stack-1m2r3s/README.md](docker-stack-1m2r3s/README.md)（1 主 2 从 3 Sentinel，`docker stack deploy`）。

## Swarm 3 主 3 从 Cluster

见 [docker-stack/README.md](docker-stack/README.md)。

---

### 所有文件将会创建到 /docker/redis 目录中

```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 redis-stack.yml  conf.d data
sh init.sh

# 启动 redis
sh start.sh

# 或
docker-compose -f /docker/redis/8/redis-stack.yml up -d

# 修改配置文件后
# 重启 redis
docker-compose -f /docker/redis/8/redis-stack.yml restart

# 停止 redis
docker-compose -f /docker/redis/8/redis-stack.yml down
```
---
#### 开启 aof 方法 [开启后会降低 redis 效率]
```shell script
redis.conf
appendonly no -> appendonly yes 
```

---
#### CentOS 7 安装 redis
```shell script
#### 安装 redis 官方 rpm 源
rpm -ivh http://redis.org/packages/centos/7/noarch/RPMS/redis-release-centos-7-0.el7.ngx.noarch.rpm
#### 安装 官方 redis
yum install  -y redis
```