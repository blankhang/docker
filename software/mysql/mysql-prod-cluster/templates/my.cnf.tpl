[mysql]
default-character-set=utf8mb4

[mysqld]
# ========================
# 基础（每节点改 server-id / report_host / relay-log）
# ========================
port=55511

server-id=N
report_host=sz-N
report_port=55511

bind-address=0.0.0.0

character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
init_connect='SET NAMES utf8mb4'

sql_mode=NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO
explicit_defaults_for_timestamp=true
default-storage-engine=InnoDB

mysql_native_password=ON

# ========================
# 连接
# ========================
max_connections=1000
max_connect_errors=100000

wait_timeout=28800
interactive_timeout=28800

open_files_limit=65535
thread_cache_size=256

max_allowed_packet=256M

table_open_cache=4096
table_definition_cache=4096

# ========================
# InnoDB
# ========================
innodb_buffer_pool_size=4G
innodb_buffer_pool_instances=4

innodb_redo_log_capacity=2G

innodb_flush_log_at_trx_commit=1
sync_binlog=1

# ========================
# Binlog / GTID / Group Replication 基础
# ========================
log-bin=mysql-bin
log_replica_updates=ON

binlog_format=ROW

gtid_mode=ON
enforce_gtid_consistency=ON

relay_log_recovery=ON

# 建议显式指定 relay log，避免 hostname 变更导致复制异常
relay-log=sz-N-relay-bin

# Group Replication 大事务限制（默认约 143MB）
group_replication_transaction_size_limit=1073741824

# ========================
# 日志
# ========================
log-error=/var/log/mysql/mysql.log

[mysqld_safe]
pid-file=/var/run/mysql/mysql.pid
