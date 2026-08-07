#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/env/sz.env"
set -a
# shellcheck source=/dev/null
source "${ENV_FILE}"
set +a
STACK_NAME="${STACK_NAME:-redis-ha-sz}"
cd "${ROOT}"
echo "deploy stack=${STACK_NAME} compose=redis-stack.yml"
echo "  redis 55701..55705 host / sentinel 55711 host quorum=3"
echo "  nodes: ${NODE1_HOSTNAME}..${NODE5_HOSTNAME}"
docker stack deploy -c redis-stack.yml "${STACK_NAME}"
docker service ls --filter "name=${STACK_NAME}"
