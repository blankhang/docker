#!/usr/bin/env bash
# 在目标宿主机准备数据目录（RabbitMQ 官方镜像用户 uid/gid 999）
set -euo pipefail
BASE="${1:-/docker/rabbitmq/rabbitmq-prod-stack}"
NODE_IDX="${2:-}"
if [[ -z "$NODE_IDX" ]]; then
  echo "usage: $0 /docker/rabbitmq/rabbitmq-prod-stack <1|2|3|4|5>"
  exit 1
fi
DIR="$BASE/data-rabbitmq-$NODE_IDX"
mkdir -p "$DIR"
chown -R 999:999 "$DIR"
chmod 700 "$DIR"
echo "ready: $DIR"
ls -la "$BASE"
