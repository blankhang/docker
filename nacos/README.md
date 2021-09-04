# docker nacos

### 所有文件将会创建到 /docker/nacos 目录中

启动nacos前需要先启动 mysql 或修改/docker/nacos/docker-compose.yml mysql配置为其它的mysql连接

```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  conf.d data
sh init.sh

# 启动
sh start.sh

# 或
docker-compose -f /docker/nacos/docker-compose.yml up -d

# 重启
docker-compose -f /docker/nacos/docker-compose.yml restart

# 停止
docker-compose -f /docker/nacos/docker-compose.yml down
```