#!/usr/bin/env bash
set -euo pipefail
DEPLOY_ROOT="${REDIS_DEPLOY_ROOT:-/docker/redis/redis-ha-sz}"
BASE="${DEPLOY_ROOT}/data"
mkdir -p "${BASE}/master" \
  "${BASE}/replica-1" "${BASE}/replica-2" "${BASE}/replica-3" "${BASE}/replica-4"
chmod 755 "${DEPLOY_ROOT}" "${BASE}" "${BASE}/master" \
  "${BASE}/replica-1" "${BASE}/replica-2" "${BASE}/replica-3" "${BASE}/replica-4"
echo "ok ${BASE}/{master,replica-1..4}"
echo "secret（独立密码）: printf '%s' \"\$REDIS_PASSWORD\" | docker secret create redis_ha_sz_password_v3 -"
echo "deploy: cd ${DEPLOY_ROOT} && ./scripts/deploy.sh"
