#!/usr/bin/env bash
# 仅在确认扩容后使用：在目标机创建目录结构（不启动、不加入集群）
set -euo pipefail

BASE=/docker/mysql/mysql-prod-cluster
mkdir -p "$BASE"/{conf,data,log,router}
chmod 750 "$BASE"/log "$BASE"/router || true
echo "prepared: $BASE"
ls -la "$BASE"
