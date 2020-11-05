# docker gogs git私服
```shell script
# 所有文件将会创建到 /docker/gogs 目录中
# 复制 init.sh 到 /docker/gogs 目录
# 赋予 init.sh 执行权限
chmod 755 init.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  data log start.sh
sh init.sh

# 启动 gogs
sh start.sh
```