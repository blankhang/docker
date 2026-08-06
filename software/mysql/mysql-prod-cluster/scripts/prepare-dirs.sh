#!/usr/bin/env bash
# 在目标机创建目录结构（不启动、不加入集群）
# mysql:8.4 容器内 mysql 用户为 uid/gid 999，bind-mount 的 data/log 必须对齐
set -euo pipefail

BASE=/docker/mysql/mysql-prod-cluster
MYSQL_UID=999
MYSQL_GID=999

mkdir -p "$BASE"/{conf,data,log,router}
chown -R "${MYSQL_UID}:${MYSQL_GID}" "$BASE"/data "$BASE"/log
chmod 750 "$BASE"/data "$BASE"/log "$BASE"/router
touch "$BASE"/log/mysql.log
chown "${MYSQL_UID}:${MYSQL_GID}" "$BASE"/log/mysql.log
chmod 640 "$BASE"/log/mysql.log
# Router bootstrap 同样以 999 写配置
chown -R "${MYSQL_UID}:${MYSQL_GID}" "$BASE"/router

echo "prepared: $BASE"
ls -lan "$BASE" "$BASE"/data "$BASE"/log "$BASE"/router
