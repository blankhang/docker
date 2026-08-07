#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
set -a
# shellcheck source=/dev/null
source "${ROOT}/env/sz.env"
if [[ -f "${ROOT}/.env" ]]; then
  # shellcheck source=/dev/null
  source "${ROOT}/.env"
fi
set +a
if [[ -z "${REDIS_PASSWORD:-}" ]]; then
  echo "export REDIS_PASSWORD=...（或写在 ${ROOT}/.env）" >&2
  exit 1
fi
PW="$REDIS_PASSWORD"
MASTER_IP="${MASTER_INTERNAL_IP}"
echo "=== master ${MASTER_IP}:55701 ==="
docker run --rm --network host redis:8.8.0-alpine \
  redis-cli -h "$MASTER_IP" -p 55701 -a "$PW" --no-auth-warning INFO replication \
  | grep -E '^(role|connected_slaves|slave[0-9]|master_host|master_port)'
echo "DBSIZE=$(docker run --rm --network host redis:8.8.0-alpine redis-cli -h "$MASTER_IP" -p 55701 -a "$PW" --no-auth-warning DBSIZE)"
echo "=== sentinel ${MASTER_IP}:55711 ==="
docker run --rm --network host redis:8.8.0-alpine \
  redis-cli -h "$MASTER_IP" -p 55711 -a "$PW" --no-auth-warning SENTINEL get-master-addr-by-name myMasterHa
docker run --rm --network host redis:8.8.0-alpine \
  redis-cli -h "$MASTER_IP" -p 55711 -a "$PW" --no-auth-warning SENTINEL master myMasterHa \
  | paste - - | egrep 'ip|port|flags|num-slaves|num-other|quorum'
echo "=== 30s 稳定性（不应降级）==="
ok=1
for i in 1 2 3 4 5 6; do
  role=$(docker run --rm --network host redis:8.8.0-alpine \
    redis-cli -h "$MASTER_IP" -p 55701 -a "$PW" --no-auth-warning INFO replication \
    | awk -F: '/^role:/{print $2}' | tr -d '\r')
  echo "  [$i] role=$role"
  [[ "$role" == "master" ]] || ok=0
  sleep 5
done
[[ "$ok" == "1" ]] || { echo "FAIL: 新主被降级" >&2; exit 1; }
echo "=== placement ==="
docker stack ps redis-ha-sz --filter desired-state=running --format 'table {{.Name}}\t{{.Node}}\t{{.CurrentState}}'
echo "OK"
