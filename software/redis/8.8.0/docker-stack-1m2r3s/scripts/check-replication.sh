#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-${REGION:-sz}}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/env/${REGION}.env"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +a
fi

if [ -n "${REDIS_PASSWORD_FILE:-}" ] && [ -r "${REDIS_PASSWORD_FILE}" ]; then
  IFS= read -r REDIS_PASSWORD < "${REDIS_PASSWORD_FILE}" || true
fi

if [ -z "${REDIS_PASSWORD:-}" ]; then
  echo "请设置 REDIS_PASSWORD 或 REDIS_PASSWORD_FILE（与 secret redis_1m2r3s_password 一致）" >&2
  exit 1
fi

REDIS_PASSWORD="${REDIS_PASSWORD//$'\r'/}"
while [[ "$REDIS_PASSWORD" == *$'\n' ]]; do REDIS_PASSWORD="${REDIS_PASSWORD%$'\n'}"; done

MASTER_INTERNAL_IP="${MASTER_INTERNAL_IP:-172.29.240.103}"
STACK_NAME="${STACK_NAME:-redis-stack-1m2r3s}"
STACK_NET="${STACK_NET:-${STACK_NAME}_redis-repl-net}"
MASTER_NAME="${SENTINEL_MASTER_NAME:-myMaster}"
SENTINEL_HOST="${SENTINEL_HOST:-redis-sentinel-1}"

EXPECTED_SLAVES=2
if [[ "${REGION}" == "sz" ]] || [[ -n "${NODE4_HOSTNAME:-}" ]]; then
  EXPECTED_SLAVES=4
fi

echo "=== region=${REGION} expected master=${MASTER_INTERNAL_IP}:55502 slaves=${EXPECTED_SLAVES} ==="

echo "=== 主节点 PING ==="
docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h redis-master -p 55502 -a "${REDIS_PASSWORD}" --no-auth-warning PING

echo ""
echo "=== 主节点复制状态 ==="
REPL=$(docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h redis-master -p 55502 -a "${REDIS_PASSWORD}" --no-auth-warning INFO replication)
echo "${REPL}" | grep -E '^(role|connected_slaves|slave[0-9])'
SLAVES=$(echo "${REPL}" | awk -F: '/^connected_slaves:/{print $2}' | tr -d '\r')
if [[ "${SLAVES}" != "${EXPECTED_SLAVES}" ]]; then
  echo "警告：connected_slaves=${SLAVES}，期望 ${EXPECTED_SLAVES}" >&2
fi

check_replica() {
  local name=$1 port=$2
  echo ""
  echo "=== ${name} ROLE (port ${port}) ==="
  docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
    redis-cli -h "${name}" -p "${port}" -a "${REDIS_PASSWORD}" --no-auth-warning ROLE
}

check_replica redis-replica-1 55512
check_replica redis-replica-2 55513
if [[ "${EXPECTED_SLAVES}" -ge 4 ]]; then
  check_replica redis-replica-3 55514
  check_replica redis-replica-4 55515
fi

echo ""
echo "=== Sentinel：当前 master 地址（internal 模式应为 ${MASTER_INTERNAL_IP} 55502）==="
MASTER_ADDR=$(docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h "${SENTINEL_HOST}" -p 55503 -a "${REDIS_PASSWORD}" --no-auth-warning \
  sentinel get-master-addr-by-name "${MASTER_NAME}")
echo "${MASTER_ADDR}"
if echo "${MASTER_ADDR}" | grep -qE '^10\.0\.'; then
  echo "警告：get-master-addr 为 overlay 10.0.x.x，请检查 REDIS_MONITOR_MODE" >&2
  exit 1
fi
if ! echo "${MASTER_ADDR}" | grep -q "${MASTER_INTERNAL_IP%.*}"; then
  echo "警告：get-master-addr 未包含本区域 master 内网段（${MASTER_INTERNAL_IP}），可能仍指向其他机房 IP" >&2
  exit 1
fi

echo ""
echo "=== Sentinel：master 监控摘要 ==="
docker run --rm --network "${STACK_NET}" redis:8.8.0-alpine \
  redis-cli -h "${SENTINEL_HOST}" -p 55503 -a "${REDIS_PASSWORD}" --no-auth-warning \
  sentinel master "${MASTER_NAME}" \
  | grep -E '^(name|ip|port|flags|num-slaves|num-other-sentinels|quorum)'
