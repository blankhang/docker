#!/usr/bin/env bash
set -euo pipefail

# 宿主机部署根目录（三台 Swarm 节点均需存在对应 data 子目录）
DEPLOY_ROOT="${REDIS_DEPLOY_ROOT:-/docker/redis/redis-stack-1m2r3s}"
BASE="${REDIS_DATA_BASE:-${DEPLOY_ROOT}/data}"

mkdir -p "${BASE}/master" "${BASE}/replica-1" "${BASE}/replica-2"
chmod 755 "${DEPLOY_ROOT}" "${BASE}" "${BASE}/master" "${BASE}/replica-1" "${BASE}/replica-2"

echo "部署根目录: ${DEPLOY_ROOT}"
echo "数据目录已创建："
echo "  ${BASE}/master"
echo "  ${BASE}/replica-1"
echo "  ${BASE}/replica-2"
echo ""
echo "若尚未创建 Swarm Secret，在 manager 上执行："
echo "  printf '%s' "${REDIS_PASSWORD:-changeme}" | docker secret create redis_1m2r3s_password -"
echo ""
echo "部署（在 ${DEPLOY_ROOT} 下，或本仓库 docker-stack-1m2r3s 目录）："
echo "  cd ${DEPLOY_ROOT}"
echo "  docker stack deploy -c redis-stack.yml redis-1m2r3s"
