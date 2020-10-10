# docker mssql-server 2019
```shell script

# 所有文件将会创建到 /docker/mssql-server 目录中
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  data log secrets
sh init.sh

# 在启动 mssql-server [生产环境]前务必修改密码!!!

# 启动 mssql-server
sh start.sh
```