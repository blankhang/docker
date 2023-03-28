# docker mysql 8

### 所有文件将会创建到 /docker/mysql 目录中

```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  conf data log
sh init.sh

# 启动 mysql
sh start.sh
# 或
docker-compose -f /docker/mysql/docker-compose.yml up -d

# 修改配置文件[/docker/mysql/conf/my.cnf]后
# 重新启动 mysql
docker-compose -f /docker/mysql/docker-compose.yml restart

# 停止 mysql
docker-compose -f /docker/mysql/docker-compose.yml down

# 导出dump数据到 host主机的 /docker/mysql/all-databases.sql
docker exec mysql8 sh -c 'exec mysqldump --all-databases -uroot -p"bXnT5oJp79*nRoYfSYYo"' > /docker/mysql/all-databases.sql

# 恢复dump数据到 mysql 容器
docker exec -i mysql8 sh -c 'exec mysql -uroot -p"bXnT5oJp79*nRoYfSYYo"' < /docker/mysql/all-databases.sql
```