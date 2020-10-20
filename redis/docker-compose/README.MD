# docker redis

####
```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  conf data
sh init.sh

# 启动 redis
sh start.sh
# 或
docker-compose -f /docker/redis/docker-compose.yml up -d

# 重启 redis
docker-compose -f /docker/redis/docker-compose.yml restart

# 停止 redis
docker-compose -f /docker/redis/docker-compose.yml down
```

---
#### 开启 aof 方法 [开启后会严重降低 redis 效率]
```shell script
redis.conf
appendonly no -> appendonly yes 
```