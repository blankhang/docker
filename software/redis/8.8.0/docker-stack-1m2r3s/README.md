# Redis 8 Swarm Stack（主从 + Sentinel）

两份**完整** compose，按机房选用（不再叠加 extra）：

| 文件 | 区域 | 拓扑 |
|------|------|------|
| [redis-stack-sz.yml](redis-stack-sz.yml) | 深圳 | **1 主 4 从 + 3 Sentinel**（`xhc-sz-1..5`） |
| [redis-stack-wh.yml](redis-stack-wh.yml) | 武汉 | **1 主 2 从 + 3 Sentinel**（`xhc-wh-1..3`） |

```bash
./scripts/deploy.sh sz   # docker stack deploy -c redis-stack-sz.yml
./scripts/deploy.sh wh   # docker stack deploy -c redis-stack-wh.yml
```

Stack 名均为 `redis-stack-1m2r3s`；Secret：`redis_1m2r3s_password`。  
**55002** = 旧 compose；本 stack 数据口 **55502 / 55512–55515**，Sentinel **55503**。

## 1. 拓扑

### 深圳（`redis-stack-sz.yml` + [env/sz.env](env/sz.env)）

| 服务 | 主机 | 端口 |
|------|------|------|
| master + sentinel-1 | `xhc-sz-1` | 55502 / 55503（仅 sentinel-1 发布） |
| replica-1 + sentinel-2 | `xhc-sz-2` | 55512 |
| replica-2 + sentinel-3 | `xhc-sz-3` | 55513 |
| replica-3 | `xhc-sz-4` | 55514 |
| replica-4 | `xhc-sz-5` | 55515 |

内网：`.103/.104/.105`（240 段）、`.238.1/.238.2`（4/5）。

### 武汉（`redis-stack-wh.yml` + [env/wh.env](env/wh.env)）

| 服务 | 主机 | 端口 |
|------|------|------|
| master + sentinel-1 | `xhc-wh-1` | 55502 / 55503 |
| replica-1 + sentinel-2 | `xhc-wh-2` | 55512 |
| replica-2 + sentinel-3 | `xhc-wh-3` | 55513 |

内网：`172.23.108.73–75`。

Sentinel：`myMaster`，quorum `2`。hostname 硬约束与 announce IP 一一对应。

## 2. 重装（推荐流程）

### 深圳 5 节点从零 / 整机重装

```bash
# 1) 同步本目录到 sz-1..5 的 /docker/redis/redis-stack-1m2r3s
# 2) 每台：
cd /docker/redis/redis-stack-1m2r3s && ./scripts/prepare.sh

# 3) manager（首次）：
printf '%s' "$REDIS_PASSWORD" | docker secret create redis_1m2r3s_password -

# 4) manager：
./scripts/deploy.sh sz

# 5) 验收：
export REDIS_PASSWORD='...'
./scripts/check-replication.sh sz   # 期望 connected_slaves=4
```

### 武汉 3 节点

同上，节点改为 wh-1..3，执行 `./scripts/deploy.sh wh` / `check-replication.sh wh`（期望 `connected_slaves=2`）。

### 已有 stack 只更新定义

同步对应 `redis-stack-sz.yml` 或 `redis-stack-wh.yml` + `env/*.env` 后再次 `./scripts/deploy.sh sz|wh`。  
若报 Swarm config 不可变：递增 `REDIS_CONFIG_VERSION` / `SENTINEL_CONFIG_VERSION` 再 deploy（数据在 bind volume，不丢；服务会滚动）。

## 3. 防火墙（VPC）

| 端口 | sz | wh |
|------|----|----|
| 55502 | `.103`（+ 公网 sz-1） | `.73` |
| 55512 / 55513 | `.104` / `.105` | `.74` / `.75` |
| 55514 / 55515 | `.238.1` / `.238.2`（仅 sz） | — |
| 55503 | sz-1..3 内网 | wh-1..3 内网 |

## 4. Spring 客户端

- Sentinel nodes **仍为 3 个 `*:55503`**（不必为从库加节点）
- **不要写** `host`/`port`（勿留旧 **55002**）
- 示例：[spring/application-redis-sentinel.example.yml](spring/application-redis-sentinel.example.yml)  
- 直连 dev：[spring/application-redis-direct.example.yml](spring/application-redis-direct.example.yml) → `55502`

## 5. 运维

| 操作 | 命令 |
|------|------|
| 部署 | `./scripts/deploy.sh sz\|wh` |
| 验收 | `./scripts/check-replication.sh sz\|wh` |
| 重建 Sentinel | `docker service update --force redis-stack-1m2r3s_redis-sentinel-{1,2,3}` |
| 下线 | `docker stack rm redis-stack-1m2r3s` |

## 6. 文件

```
docker-stack-1m2r3s/
├── redis-stack-sz.yml    # 深圳完整 5 节点
├── redis-stack-wh.yml    # 武汉完整 3 节点
├── env/sz.env | wh.env
├── conf/
├── scripts/deploy.sh | prepare.sh | check-replication.sh
└── spring/
```
