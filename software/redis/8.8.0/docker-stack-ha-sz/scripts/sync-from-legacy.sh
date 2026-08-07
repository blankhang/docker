#!/usr/bin/env bash
# 从旧 redis-stack-1m2r3s（55502）同步到新 redis-ha-sz（55701）
# 不停旧集群。新集群 requirepass 必须从一开始就与旧不同（旧 Sentinel 无法鉴权干扰）。
# 同步时仅临时把 masterauth 设为旧密码以便 REPLICAOF。
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

STACK_NAME="${STACK_NAME:-redis-ha-sz}"
LEGACY_IP="${LEGACY_MASTER_IP:-172.29.240.103}"
LEGACY_PORT="${LEGACY_MASTER_PORT:-55502}"
LEGACY_SENTINEL_PORT="${LEGACY_SENTINEL_PORT:-55503}"
LEGACY_MASTER_NAME="${LEGACY_MASTER_NAME:-myMaster}"
NEW_IP="${MASTER_INTERNAL_IP:-172.29.240.103}"
NEW_PORT="${MASTER_INTERNAL_PORT:-55701}"
SENTINEL_PORT="${SENTINEL_PORT:-55711}"
MASTER_NAME="${SENTINEL_MASTER_NAME:-myMasterHa}"

NEW_PW="${REDIS_PASSWORD:-}"
LEGACY_PW="${LEGACY_REDIS_PASSWORD:-}"
if [[ -z "${LEGACY_PW}" && -f /docker/redis/redis-stack-1m2r3s/.env ]]; then
  # shellcheck source=/dev/null
  LEGACY_PW="$(set -a; source /docker/redis/redis-stack-1m2r3s/.env; set +a; printf '%s' "${REDIS_PASSWORD:-}")"
fi

if [[ -z "${NEW_PW}" ]]; then
  echo "请在 ${ROOT}/.env 设置 REDIS_PASSWORD=新集群独立密码" >&2
  exit 1
fi
if [[ -z "${LEGACY_PW}" ]]; then
  echo "请 export LEGACY_REDIS_PASSWORD=旧集群密码（或保留旧 .env）" >&2
  exit 1
fi
if [[ "${NEW_PW}" == "${LEGACY_PW}" ]]; then
  echo "新/旧密码相同会再次被旧 Sentinel 干扰，请换独立 REDIS_PASSWORD" >&2
  exit 1
fi

redis_cli() {
  local host="$1" port="$2" pass="$3"
  shift 3
  docker run --rm --network host redis:8.8.0-alpine \
    redis-cli -h "${host}" -p "${port}" -a "${pass}" --no-auth-warning "$@"
}

echo "=== 1) 缩容新 Sentinel ==="
for i in 1 2 3 4 5; do
  docker service scale "${STACK_NAME}_redis-sentinel-${i}=0" --detach=true || true
done
sleep 8

echo "=== 2) 临时 masterauth=旧密码，REPLICAOF 旧主 ==="
echo -n "old PING: "; redis_cli "${LEGACY_IP}" "${LEGACY_PORT}" "${LEGACY_PW}" PING
echo -n "new PING: "; redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" PING
echo "old DBSIZE=$(redis_cli "${LEGACY_IP}" "${LEGACY_PORT}" "${LEGACY_PW}" DBSIZE)  new(before)=$(redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" DBSIZE)"

redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" CONFIG SET masterauth "${LEGACY_PW}"
redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" REPLICAOF "${LEGACY_IP}" "${LEGACY_PORT}"

echo "=== 3) 等待复制追上 ==="
for i in $(seq 1 180); do
  info=$(redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" INFO replication || true)
  role=$(echo "$info" | awk -F: '/^role:/{print $2}' | tr -d '\r')
  link=$(echo "$info" | awk -F: '/^master_link_status:/{print $2}' | tr -d '\r')
  echo "[$i] role=$role link=$link"
  if [[ "$role" == "slave" && "$link" == "up" ]]; then
    sleep 3
    o1=$(redis_cli "${LEGACY_IP}" "${LEGACY_PORT}" "${LEGACY_PW}" INFO replication | awk -F: '/^master_repl_offset:/{print $2}' | tr -d '\r')
    o2=$(redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" INFO replication | awk -F: '/^slave_repl_offset:/{print $2}' | tr -d '\r')
    echo "  offsets old=$o1 new=$o2"
    if [[ -n "$o1" && -n "$o2" && "$o1" == "$o2" ]]; then
      echo "offset matched"
      break
    fi
  fi
  sleep 2
done

echo "=== 4) 提升新主，masterauth 改回新密码 ==="
redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" REPLICAOF NO ONE
redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" CONFIG SET masterauth "${NEW_PW}"
sleep 2
redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" INFO replication | grep -E '^(role|connected_slaves|master_repl_offset)'
echo "DBSIZE new=$(redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" DBSIZE) old=$(redis_cli "${LEGACY_IP}" "${LEGACY_PORT}" "${LEGACY_PW}" DBSIZE)"

echo "=== 5) 旧 Sentinel RESET（清可能学到的 55701）==="
for ip in "${NODE1_INTERNAL_IP}" "${NODE2_INTERNAL_IP}" "${NODE3_INTERNAL_IP}"; do
  redis_cli "${ip}" "${LEGACY_SENTINEL_PORT}" "${LEGACY_PW}" SENTINEL RESET "${LEGACY_MASTER_NAME}" || true
done

echo "=== 6) force 从库跟随新主 ==="
for i in 1 2 3 4; do
  docker service update --force "${STACK_NAME}_redis-replica-${i}" --detach=true || true
done
for i in $(seq 1 60); do
  role=$(redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" INFO replication | awk -F: '/^role:/{print $2}' | tr -d '\r')
  slaves=$(redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" INFO replication | awk -F: '/^connected_slaves:/{print $2}' | tr -d '\r')
  echo "[$i] role=$role connected_slaves=$slaves"
  if [[ "$role" == "slave" ]]; then
    redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" REPLICAOF NO ONE || true
    redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" CONFIG SET masterauth "${NEW_PW}" || true
  fi
  [[ "$role" == "master" && "$slaves" == "4" ]] && break
  sleep 3
done

echo "=== 7) 拉起 5 Sentinel ==="
for i in 1 2 3 4 5; do
  docker service scale "${STACK_NAME}_redis-sentinel-${i}=1" --detach=true || true
done
sleep 12
for i in $(seq 1 36); do
  bad=$(docker service ls --filter "name=${STACK_NAME}" --format '{{.Name}} {{.Replicas}}' | grep -v '1/1' || true)
  echo "services wait $i bad=[$bad]"
  [[ -z "$bad" ]] && break
  sleep 5
done

echo "=== 8) 验收（30s 不降级）==="
ok=1
for i in $(seq 1 10); do
  info=$(redis_cli "${NEW_IP}" "${NEW_PORT}" "${NEW_PW}" INFO replication)
  role=$(echo "$info" | awk -F: '/^role:/{print $2}' | tr -d '\r')
  slaves=$(echo "$info" | awk -F: '/^connected_slaves:/{print $2}' | tr -d '\r')
  addr=$(redis_cli "${NEW_IP}" "${SENTINEL_PORT}" "${NEW_PW}" SENTINEL get-master-addr-by-name "${MASTER_NAME}" | tr '\n' ' ')
  echo "[watch $i] role=$role slaves=$slaves sentinel=[$addr]"
  if [[ "$role" != "master" || "$slaves" != "4" ]] || ! echo "$addr" | grep -q "${NEW_PORT}"; then
    ok=0
    break
  fi
  sleep 3
done

redis_cli "${NEW_IP}" "${SENTINEL_PORT}" "${NEW_PW}" SENTINEL master "${MASTER_NAME}" \
  | paste - - | egrep 'ip|port|flags|num-slaves|num-other|quorum' || true
echo "old still: $(redis_cli "${LEGACY_IP}" "${LEGACY_PORT}" "${LEGACY_PW}" INFO replication | grep connected_slaves)"
[[ "$ok" == "1" ]] || { echo "验收失败" >&2; exit 1; }
echo "DONE — 新 ${NEW_IP}:${NEW_PORT} / Sentinel ${SENTINEL_PORT} / ${MASTER_NAME}；旧 ${LEGACY_IP}:${LEGACY_PORT} 仍在"
