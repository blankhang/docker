#!/usr/bin/env bash
set -euo pipefail

DEPLOY_ROOT="${REDIS_DEPLOY_ROOT:-/docker/redis/redis-stack-1m2r3s}"
BASE="${REDIS_DATA_BASE:-${DEPLOY_ROOT}/data}"

# sz 用 master + replica-1..4；wh 用 master + replica-1..2（多建无害）
mkdir -p \
  "${BASE}/master" \
  "${BASE}/replica-1" \
  "${BASE}/replica-2" \
  "${BASE}/replica-3" \
  "${BASE}/replica-4"
chmod 755 "${DEPLOY_ROOT}" "${BASE}" \
  "${BASE}/master" "${BASE}/replica-1" "${BASE}/replica-2" \
  "${BASE}/replica-3" "${BASE}/replica-4"

echo "部署根目录: ${DEPLOY_ROOT}"
echo "数据目录: ${BASE}/{master,replica-1..4}"
echo ""
echo "Secret（仅首次，manager）："
echo "  printf '%s' \"\${REDIS_PASSWORD}\" | docker secret create redis_1m2r3s_password -"
echo ""
echo "重装 / 部署："
echo "  cd ${DEPLOY_ROOT}"
echo "  ./scripts/deploy.sh sz   # → redis-stack-sz.yml（5 节点）"
echo "  ./scripts/deploy.sh wh   # → redis-stack-wh.yml（3 节点）"
