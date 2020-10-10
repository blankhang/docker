# docker mssql-server 2019
```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应目录创建 docker-compose.yml  data log 文件生成
sh init.sh

# 在启动 mssql-server [生产环境]前务必修改密码!!!

# 启动 mssql-server
sh start.sh
```