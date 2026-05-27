#!/usr/bin/env bash
set -euo pipefail

if [ -n "${REDIS_PASSWORD_FILE:-}" ] && [ -r "${REDIS_PASSWORD_FILE}" ]; then
  IFS= read -r REDIS_PASSWORD < "${REDIS_PASSWORD_FILE}" || true
fi

if [ -z "${REDIS_PASSWORD:-}" ]; then
  echo "请设置 REDIS_PASSWORD 或 REDIS_PASSWORD_FILE（与 secret redis_1m2r3s_password 一致）" >&2
  exit 1
fi

REDIS_PASSWORD="${REDIS_PASSWORD//$'\r'/}"
while [[ "$REDIS_PASSWORD" == *$'\n' ]]; do REDIS_PASSWORD="${REDIS_PASSWORD%$'\n'}"; done

# Swarm stack 名（与 redis-stack.yml 部署时一致，非宿主机目录名）
STACK_NAME="${STACK_NAME:-redis-1m2r3s}"
STACK_NET="${STACK_NET:-${STACK_NAME}_redis-repl-net}"
MASTER_NAME="${SENTINEL_MASTER_NAME:-myMaster}"
SENTINEL_HOST="${SENTINEL_HOST:-redis-sentinel-1}"

echo "=== 主节点 PING ==="
docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h redis-master -p 55502 -a "${REDIS_PASSWORD}" --no-auth-warning PING

echo ""
echo "=== 主节点复制状态 ==="
docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h redis-master -p 55502 -a "${REDIS_PASSWORD}" --no-auth-warning INFO replication \
  | grep -E '^(role|connected_slaves|slave[0-9])'

echo ""
echo "=== 从节点 1 ROLE ==="
docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h redis-replica-1 -p 55512 -a "${REDIS_PASSWORD}" --no-auth-warning ROLE

echo ""
echo "=== 从节点 2 ROLE ==="
docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h redis-replica-2 -p 55513 -a "${REDIS_PASSWORD}" --no-auth-warning ROLE

echo ""
echo "=== Sentinel：当前 master 地址（internal 模式应为 172.29.240.103 55502）==="
MASTER_ADDR=$(docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h "${SENTINEL_HOST}" -p 55503 -a "${REDIS_PASSWORD}" --no-auth-warning \
  sentinel get-master-addr-by-name "${MASTER_NAME}")
echo "${MASTER_ADDR}"
if echo "${MASTER_ADDR}" | grep -qE '^10\.0\.'; then
  echo "警告：get-master-addr 为 overlay 10.0.x.x，请检查 REDIS_MONITOR_MODE" >&2
  exit 1
fi

echo ""
echo "=== Sentinel：master 监控摘要 ==="
docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h "${SENTINEL_HOST}" -p 55503 -a "${REDIS_PASSWORD}" --no-auth-warning \
  sentinel master "${MASTER_NAME}" \
  | grep -E '^(name|ip|port|flags|num-slaves|num-other-sentinels|quorum)'
