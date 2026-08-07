#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-}"
if [[ -z "${REGION}" ]]; then
  echo "用法: $0 sz|wh" >&2
  echo "  sz — redis-stack-sz.yml（5 节点：1 主 4 从 + 3 Sentinel）" >&2
  echo "  wh — redis-stack-wh.yml（3 节点：1 主 2 从 + 3 Sentinel）" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/env/${REGION}.env"
COMPOSE_FILE="${ROOT}/redis-stack-${REGION}.yml"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "缺少 ${ENV_FILE}" >&2
  exit 1
fi
if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "缺少 ${COMPOSE_FILE}" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "${ENV_FILE}"
set +a

STACK_NAME="${STACK_NAME:-redis-stack-1m2r3s}"
cd "${ROOT}"

echo "deploy region=${REGION} stack=${STACK_NAME}"
echo "  compose: redis-stack-${REGION}.yml"
echo "  nodes: ${NODE1_HOSTNAME}(${NODE1_INTERNAL_IP}) / ${NODE2_HOSTNAME}(${NODE2_INTERNAL_IP}) / ${NODE3_HOSTNAME}(${NODE3_INTERNAL_IP})"
if [[ -n "${NODE4_HOSTNAME:-}" ]]; then
  echo "         ${NODE4_HOSTNAME}(${NODE4_INTERNAL_IP}) / ${NODE5_HOSTNAME}(${NODE5_INTERNAL_IP})"
fi

docker stack deploy -c "redis-stack-${REGION}.yml" "${STACK_NAME}"
docker service ls --filter "name=${STACK_NAME}"
