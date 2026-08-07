# 深圳 5 节点 Redis 高可用部署教程（0 → 1）

本文说明如何从零部署 **`redis-ha-sz`**：1 主 4 从 + 5 Sentinel（quorum=3），任意挂 2 台仍可选主。  
仓库路径：`software/redis/8.8.0/docker-stack-ha-sz/`。

> **安全约定**：SSH 一律使用本机 `~/.ssh/config` 里的 Host 别名（如 `ssh root@sz-1`）。  
> **文档与命令中禁止出现 SSH 端口号、公网 IP、`-p`、`HostName=` 等写法。**

---

## 0. 架构一览

| 项 | 值 |
|----|-----|
| 宿主机目录 | `/docker/redis/redis-ha-sz` |
| Stack 名 | `redis-ha-sz` |
| Swarm Secret | `redis_ha_sz_password_v3`（密码**必须**与旧集群不同） |
| Redis 端口（`publish_mode: host`） | **55701** master … **55705** replica |
| Sentinel 端口（每台一只） | **55711** |
| Sentinel master 名 | `myMasterHa` |
| Quorum | **3** |
| 镜像 | `redis:8.8.0-alpine` |
| 健康检查 | 10 个服务均有 `healthcheck`（鉴权 `PING`） |

| Swarm 节点 hostname | 内网 IP | Redis | Sentinel |
|---------------------|---------|-------|----------|
| `xhc-sz-1` | `172.29.240.103` | master **55701** | **55711** |
| `xhc-sz-2` | `172.29.240.104` | replica **55702** | **55711** |
| `xhc-sz-3` | `172.29.240.105` | replica **55703** | **55711** |
| `xhc-sz-4` | `172.29.238.1` | replica **55704** | **55711** |
| `xhc-sz-5` | `172.29.238.2` | replica **55705** | **55711** |

- **不占用** `55511`（MySQL）。
- 旧集群 `redis-stack-1m2r3s`（`55502` / `55503` / `55512–55515`）可并行运行，**本教程不自动停旧**。
- 556xx 端口轮次已废弃，勿再用。

拓扑示意：

```text
应用 → 五台 :55711 (Sentinel, quorum=3)
         └─ GET-MASTER-ADDR myMasterHa → 当前主 :55701..55705 之一

xhc-sz-1  55701 master  + 55711 sentinel
xhc-sz-2  55702 replica + 55711 sentinel
xhc-sz-3  55703 replica + 55711 sentinel
xhc-sz-4  55704 replica + 55711 sentinel
xhc-sz-5  55705 replica + 55711 sentinel
```

---

## 1. 前置条件

1. 五台已加入同一 Docker Swarm；`docker node ls` 可见 `xhc-sz-1` … `xhc-sz-5`（hostname 须与 `env/sz.env` 一致）。
2. 本机可执行：`ssh root@sz-1` … `ssh root@sz-5`（别名已配好，**不要**在命令里写端口）。
3. VPC / 安全组放行五机互访：**55701–55705**、**55711**（业务机访问 Sentinel 与数据面同理）。
4. 五机上确认端口空闲（在任意节点）：

```bash
ss -lnt | awk '($4 ~ /:5570[1-5]$|:55711$/){print}'
# 应无输出；若被占用先排查再部署
```

5. 本地已有本仓库目录：

```text
docker-stack-ha-sz/
├── redis-stack.yml
├── env/sz.env
├── conf/redis.conf
├── conf/sentinel.conf
├── scripts/prepare.sh | deploy.sh | sync-from-legacy.sh | check.sh
└── spring/application-redis-sentinel.example.yml
```

---

## 2. 同步文件到五台

在**本机**仓库根下执行（将 `SRC` 换成你的本机绝对路径）：

```bash
SRC=/path/to/docker/software/redis/8.8.0/docker-stack-ha-sz

for h in sz-1 sz-2 sz-3 sz-4 sz-5; do
  ssh root@$h "mkdir -p /docker/redis/redis-ha-sz/{env,conf,scripts,spring,data}"
  scp "$SRC/redis-stack.yml" "$SRC/README.md" root@$h:/docker/redis/redis-ha-sz/
  scp "$SRC/env/sz.env" root@$h:/docker/redis/redis-ha-sz/env/
  scp "$SRC/conf/"* root@$h:/docker/redis/redis-ha-sz/conf/
  scp "$SRC/scripts/"*.sh root@$h:/docker/redis/redis-ha-sz/scripts/
  scp "$SRC/spring/"* root@$h:/docker/redis/redis-ha-sz/spring/ 2>/dev/null || true
  ssh root@$h "chmod +x /docker/redis/redis-ha-sz/scripts/*.sh"
  echo "synced $h"
done
```

---

## 3. 准备数据目录

五台都执行（本机循环即可）：

```bash
for h in sz-1 sz-2 sz-3 sz-4 sz-5; do
  ssh root@$h 'cd /docker/redis/redis-ha-sz && ./scripts/prepare.sh'
done
```

会创建：

```text
/docker/redis/redis-ha-sz/data/{master,replica-1,replica-2,replica-3,replica-4}
```

若是**重建干净集群**，先清空旧数据（会丢该目录内 RDB/AOF）：

```bash
for h in sz-1 sz-2 sz-3 sz-4 sz-5; do
  ssh root@$h 'cd /docker/redis/redis-ha-sz && find data -mindepth 1 -maxdepth 3 -exec rm -rf {} +; ./scripts/prepare.sh'
done
```

---

## 4. 创建独立密码与 Swarm Secret

> **关键**：新集群 `requirepass` **禁止**与旧 `redis-stack-1m2r3s` 相同。  
> 同密码时旧 Sentinel 会把新节点 `REPLICAOF` 回旧主，集群会「脏掉」。

在 **sz-1**（Swarm manager 之一）上：

```bash
ssh root@sz-1
cd /docker/redis/redis-ha-sz

# 自备强密码，勿提交到 Git
NEW_PW='请换成足够长的随机串'

# 若曾部署过同名 secret，需改 env/sz.env 里 REDIS_SECRET_VERSION 后再 create 新名
printf '%s' "$NEW_PW" | docker secret create redis_ha_sz_password_v3 -

echo "REDIS_PASSWORD=$NEW_PW" > .env
chmod 600 .env
```

把 `.env` 同步到其余四台（运维脚本 / 验收用，**不要**进 Git）：

```bash
# 仍在本机执行
for h in sz-2 sz-3 sz-4 sz-5; do
  scp root@sz-1:/docker/redis/redis-ha-sz/.env root@$h:/docker/redis/redis-ha-sz/.env
done
```

确认 `env/sz.env` 中：

```bash
export REDIS_SECRET_VERSION=v3          # 与 secret 名后缀一致
export SENTINEL_MASTER_NAME=myMasterHa  # 勿与旧集群 myMaster 同名
export MASTER_INTERNAL_PORT=55701
export SENTINEL_PORT=55711
```

---

## 5. 部署 Stack

```bash
ssh root@sz-1
cd /docker/redis/redis-ha-sz

# 若残留半成品，先干净删除并等到服务与网络都为 0
docker stack rm redis-ha-sz || true
# 等待：docker service ls --filter name=redis-ha-sz 为空
# 等待：docker network ls | grep redis-ha-sz 无输出
# 建议再多等数秒，避免「network not found」竞态

./scripts/deploy.sh
```

期望创建 **10** 个服务：

- `redis-ha-sz_redis-master`
- `redis-ha-sz_redis-replica-1` … `replica-4`
- `redis-ha-sz_redis-sentinel-1` … `sentinel-5`

```bash
docker service ls --filter name=redis-ha-sz
# 全部 1/1

docker stack ps redis-ha-sz --filter desired-state=running \
  --format 'table {{.Name}}\t{{.Node}}\t{{.CurrentState}}'
# 节点应落在 xhc-sz-1 .. xhc-sz-5
```

健康检查（任一台）：

```bash
docker ps --filter name=redis-ha-sz --format '{{.Names}} {{.Status}}'
# 应含 (healthy)
```

空集群冒烟（在 sz-1，密码来自 `.env`）：

```bash
set -a; source /docker/redis/redis-ha-sz/.env; set +a
docker run --rm --network host redis:8.8.0-alpine \
  redis-cli -h 127.0.0.1 -p 55701 -a "$REDIS_PASSWORD" --no-auth-warning PING
# PONG

docker run --rm --network host redis:8.8.0-alpine \
  redis-cli -h 127.0.0.1 -p 55701 -a "$REDIS_PASSWORD" --no-auth-warning INFO replication \
  | grep -E '^(role|connected_slaves)'
# role:master  connected_slaves:4

docker run --rm --network host redis:8.8.0-alpine \
  redis-cli -h 127.0.0.1 -p 55711 -a "$REDIS_PASSWORD" --no-auth-warning \
  SENTINEL get-master-addr-by-name myMasterHa
# 172.29.240.103
# 55701
```

到此即 **空集群 0→1 部署完成**。无旧数据可迁时，直接进入第 7 节切流。

---

## 6. 从旧集群同步数据（可选，不停旧）

旧栈：`redis-stack-1m2r3s`，默认旧主 `172.29.240.103:55502`，Sentinel 名 `myMaster`。

脚本会：缩容新 Sentinel → 临时 `masterauth=旧密码` + `REPLICAOF` 旧主 → 追上后 `REPLICAOF NO ONE` → `masterauth` 改回新密码 → 旧 Sentinel `RESET` → 拉起从库与 5 Sentinel。

```bash
ssh root@sz-1
cd /docker/redis/redis-ha-sz
# .env 里已是新密码；旧密码默认读 /docker/redis/redis-stack-1m2r3s/.env
# 也可：export LEGACY_REDIS_PASSWORD='旧密码'

./scripts/sync-from-legacy.sh
./scripts/check.sh
```

验收要点：

- 新主 `role:master`，`connected_slaves:4`，约 30s 不降级
- `DBSIZE` 与旧主接近
- `SENTINEL get-master-addr-by-name myMasterHa` → `172.29.240.103` / `55701`
- `num-other-sentinels:4`，`quorum:3`
- 旧 `55502` 仍在，`connected_slaves` 正常（通常为 4）

---

## 7. 应用切流

Spring 示例见 [spring/application-redis-sentinel.example.yml](spring/application-redis-sentinel.example.yml)：

```yaml
spring:
  data:
    redis:
      password: ${REDIS_PASSWORD}   # 新集群独立密码
      sentinel:
        master: myMasterHa
        nodes:
          - 172.29.240.103:55711
          - 172.29.240.104:55711
          - 172.29.240.105:55711
          - 172.29.238.1:55711
          - 172.29.238.2:55711
        password: ${REDIS_PASSWORD}
```

注意：

- **不要**再写 `spring.data.redis.host` / `port`（与 Sentinel 模式冲突）。
- 使用 **新密码** 与 **`myMasterHa`**，节点为五台 **55711**。
- 切流验证通过后，再人工下线旧栈（本仓库不自动执行）：

```bash
# 确认无业务再连旧 55502/55503 后
docker stack rm redis-stack-1m2r3s
```

---

## 8. 日常运维命令

```bash
# 服务与落点
docker service ls --filter name=redis-ha-sz
docker stack ps redis-ha-sz --filter desired-state=running

# 滚动更新配置后重新部署（改 conf 时先 bump env 里 CONFIG_VERSION）
cd /docker/redis/redis-ha-sz && ./scripts/deploy.sh

# 验收脚本
./scripts/check.sh
```

---

## 9. 故障与注意

| 现象 | 处理 |
|------|------|
| `network redis-ha-sz_redis-ha-net not found` | `stack rm` 后等网络删干净再 `deploy`；或再执行一次 `./scripts/deploy.sh` |
| 只有部分服务（如仅 master + replica-3） | 用完整 `redis-stack.yml` 再 `deploy`；检查五机 hostname / placement |
| 新主反复变成旧主从库 | 新旧密码相同或 Sentinel 名冲突；换成独立密码 + `myMasterHa`，必要时 `SENTINEL RESET myMaster`（旧） |
| Portainer 显示 `running` 无 healthy | 确认已同步带 `healthcheck` 的 yml 并重新 deploy；容器 Status 应为 `Up … (healthy)` |
| Secret 已存在无法覆盖 | 增大 `REDIS_SECRET_VERSION`（如 v4），`docker secret create redis_ha_sz_password_v4`，改 `.env` 后 deploy |

---

## 10. 文件职责

| 路径 | 说明 |
|------|------|
| `redis-stack.yml` | Swarm 完整定义（端口、placement、healthcheck） |
| `env/sz.env` | 节点 hostname / 内网 IP / 端口 / 版本号 |
| `conf/redis.conf` | Redis 公共配置 |
| `conf/sentinel.conf` | Sentinel 基座配置 |
| `scripts/prepare.sh` | 数据目录 |
| `scripts/deploy.sh` | `docker stack deploy` |
| `scripts/sync-from-legacy.sh` | 从旧 55502 导数据 |
| `scripts/check.sh` | 主从 + Sentinel + 稳定性 |
| `.env` | 仅服务器：`REDIS_PASSWORD=…`（勿提交） |

---

## 11. 检查清单（交付）

- [ ] 五机文件已同步，`prepare.sh` 已跑
- [ ] Secret + `.env` 为**独立**新密码
- [ ] 10 服务均为 `1/1`，落点 sz-1..5
- [ ] `docker ps` 均为 `(healthy)`
- [ ] Sentinel → `103:55701`，`connected_slaves:4`
- [ ]（迁数据时）`sync-from-legacy.sh` + `check.sh` 通过
- [ ] 应用改为五节点 `55711` + `myMasterHa` + 新密码
- [ ] 切流后再考虑 `docker stack rm redis-stack-1m2r3s`
