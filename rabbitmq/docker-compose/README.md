# docker redis

### 所有文件将会创建到 /docker/rabbitmq 目录中
docker-compose.yml 为3台rabbitmq 伪集群版
stack/rabbitmq-stack.yml 为 docker swarm 集群版
docker-compose-standalone.yml 为单机版

```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  conf.d data
sh init.sh

# 启动
sh start.sh

# 或
docker-compose -f /docker/rabbitmq/docker-compose.yml up -d

# 修改配置文件后
# 重启
docker-compose -f /docker/rabbitmq/docker-compose.yml restart

# 停止
docker-compose -f /docker/rabbitmq/docker-compose.yml down
```