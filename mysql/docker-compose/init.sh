#!/bin/bash

# create mysql local data store directory
mkdir  -p /docker/mysql/{conf.d,data,log}

# mysql docker running as 999
chown 999:999 /docker/mysql/{conf.d,data,log}

# create mysql's configuration file
cat << 'EOF' > /docker/mysql/conf.d/my.cnf
[mysqldump]
quick
quote-names
max_allowed_packet  = 16M

[mysqld]
# MySQL 服务的唯一编号 几个 MySQL 服务 ID 需唯一(集群中)
server-id = 1

# 修改时区为东8区
default-time-zone="+8:00"

# 表名不分区大小写
lower_case_table_names=1

# 最大连接数
max_connections = 500

# 最大错误连接数
max_connect_errors = 1000

# MySQL连接闲置超过一定时间后(单位：秒)将会被强行关闭
# MySQL默认的wait_timeout  值为8个小时, interactive_timeout参数需要同时配置才能生效
interactive_timeout = 1800
wait_timeout = 1800

# 旧密码插件
default-authentication-plugin=mysql_native_password

#pid-file      = /var/run/mysqld/mysqld.pid
#socket        = /var/run/mysqld/mysqld.sock

# 数据库的数据存放目录
datadir       = /var/lib/mysql
# 错误日志
log-error    = /var/log/mysql/error.log

# 跳过密码登陆(取消注释重置 root 密码)
#skip-grant-tables

# 设置默认排序规则
collation-server = utf8mb4_unicode_ci

# 客户端跟服务器字符编码不一致时拒绝连接
character-set-client-handshake = TRUE

# 时间格式的 0000 不报错处理
sql_mode = NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO

# 创建新表时将使用的默认存储引擎
default-storage-engine = INNODB

# 锁定等待时间由默认的50s 修改为500s
innodb_lock_wait_timeout = 500

# 事务隔离级别，默认为可重复读，mysql默认可重复读级别（此级别下可能参数很多间隙锁，影响性能）
transaction_isolation = READ-COMMITTED

# 设置client连接mysql时的字符集,防止乱码
init_connect='SET NAMES utf8mb4'

# TIMESTAMP如果没有显示声明NOT NULL，允许NULL值
explicit_defaults_for_timestamp = true

# SQL数据包发送的大小，如果有BLOB对象建议修改成1G
max_allowed_packet = 128M

# 代表受信任的函数创建者，也就是使MySQL不对函数做出限制
log_bin_trust_function_creators = 1


# 内部内存临时表的最大值 ，设置成128M。
# 比如大数据量的group by ,order by时可能用到临时表，
# 超过了这个值将写入磁盘，系统IO压力增大
tmp_table_size = 134217728
max_heap_table_size = 134217728


# 慢查询sql日志设置
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log

# 检查未使用到索引的sql
log_queries_not_using_indexes = 1

# 针对log_queries_not_using_indexes开启后，记录慢sql的频次、每分钟记录的条数
log_throttle_queries_not_using_indexes = 5

# 作为从库时生效,从库复制中如何有慢sql也将被记录
log_slow_slave_statements = 1

# 慢查询执行的秒数，必须达到此值可被记录
long_query_time = 8

# 检索的行数必须达到此值才可被记为慢查询
min_examined_row_limit = 100

log-bin = /var/lib/mysql/log.bin

# mysql binlog日志文件保存的过期时间，过期后自动删除 7 天 = 7 * 24 * 60 * 60
binlog_expire_logs_seconds = 604800

EOF

# create mysql's docker-compose file
cat << 'EOF' > /docker/mysql/docker-compose.yml
version: '3.7'
services:
  mysql:
    image: mysql:8
    hostname: mysql
    restart: always
    container_name: mysql
    user: "999:999"
    command: --default-authentication-plugin=mysql_native_password
    healthcheck:
      test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
      timeout: 15s
      retries: 10
      interval: 5s
      start_period: 10s
    environment:
      TZ: Asia/Shanghai
      MYSQL_ROOT_PASSWORD: "123456"
      #MYSQL_DATABASE: "test"
      #MYSQL_USER: "blank"
      #MYSQL_PASSWORD: "123456"
    volumes:
      - ./conf.d:/etc/mysql/conf.d
      - ./data:/var/lib/mysql
      - ./log:/var/log/mysql
      # init sql
      #- ./mysql/sql/master:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
EOF

echo -e "\033[36m init success \033[0m"
echo "now you can run start.sh to start mysql"