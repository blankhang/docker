# Elasticsearch / Kibana 9.4.1

| 目录 | 用途 |
|------|------|
| `build/` | 自定义镜像（含 IK 分词） |
| `docker-compose/` | 单机 Compose 开发/测试 |
| `docker-stack/` | Swarm 三节点生产栈 |

## Docker Compose（单机）

```shell
cd docker-compose

mkdir -p data-kibana data-elasticsearch
sudo chmod -R 1000:1000 data-*

# 修改 .env 中的 ELASTIC_PASSWORD、KIBANA_PASSWORD
docker compose up -d
```

## Docker Stack（Swarm 生产）

3 节点 Elasticsearch 集群 + 1 个 Kibana，镜像为 `blankhang/elasticsearch:9.4.1`（含 IK）与官方 `kibana:9.4.1`。

| 服务 | 节点约束 | 发布端口 | 说明 |
|------|----------|----------|------|
| es-node1 | `xhc-wh-1` | 19201→9200 | 主节点之一，Kibana 同机 |
| es-node2 | `xhc-wh-2` | 19202→9200 | |
| es-node3 | `xhc-wh-3` | 19203→9200 | |
| kibana | `xhc-wh-1` | 15601→5601 | 连接 `es-node1:9200` |

宿主机数据目录统一在 `/docker/es/es-prod-stack/`；节点间传输层 TLS 证书见 `docker-stack/conf/elastic-certificates_p12`。

### 1. 前置条件

- 三台节点已加入 **Docker Swarm**，且 hostname 分别为 `xhc-wh-1` / `xhc-wh-2` / `xhc-wh-3`（若不同，请修改 `docker-stack/es-stack.yml` 中 `deploy.placement.constraints`）。
- 将本仓库 `docker-stack/` 同步到各节点（至少 manager 节点），或统一放在 `/docker/es/es-prod-stack/` 便于路径一致。

### 2. 创建数据目录

在各节点执行（路径与 `es-stack.yml` 中 volumes 一致）：

```bash
# node-1（含 Kibana 数据）
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node1 \
  /docker/es/es-prod-stack/es-backup \
  /docker/es/es-prod-stack/data-kibana
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node1 \
  /docker/es/es-prod-stack/es-backup \
  /docker/es/es-prod-stack/data-kibana

# node-2
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node2 \
  /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node2 \
  /docker/es/es-prod-stack/es-backup

# node-3
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node3 \
  /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node3 \
  /docker/es/es-prod-stack/es-backup
```

### 3. 配置 `.env`

编辑 `docker-stack/.env`，按环境修改：

| 变量 | 说明 |
|------|------|
| `ELK_VERSION` | 镜像 tag，默认 `9.4.1` |
| `ELASTIC_PASSWORD` | ES `elastic` 用户密码 |
| `KIBANA_PASSWORD` | Kibana 连接 ES 的 `kibana_system` 密码 |
| `XPACK_*_ENCRYPTIONKEY` | Kibana 三类加密密钥（变更会导致已加密对象不可用） |

### 4. 部署

在 Swarm **manager** 上执行：

```bash
cd docker-stack
docker stack deploy --env-file .env -c es-stack.yml es-prod
```

查看状态：

```bash
docker stack services es-prod
docker service logs es-prod_es-node1 -f
```

### 5. 首次集群初始化后

`es-stack.yml` 中三节点均配置了 `cluster.initial_master_nodes`。**集群首次形成后**，应注释掉该环境变量并重新部署，避免后续重启误判为 bootstrap：

```bash
# 编辑 es-stack.yml，注释三处 cluster.initial_master_nodes 后：
docker stack deploy --env-file .env -c es-stack.yml es-prod
```

### 6. 更新 stack

修改 `es-stack.yml` 或 `.env` 后，在同一目录再次执行 `docker stack deploy`（Swarm 会滚动更新，`update_config` 为 `stop-first`）。

升级镜像版本时：先构建/拉取 `blankhang/elasticsearch:新版本`，再改 `.env` 中 `ELK_VERSION` 后部署。

### 7. 重置密码

```bash
docker exec -it $(docker ps -q -f name=es-prod_es-node1) \
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i

docker exec -it $(docker ps -q -f name=es-prod_es-node1) \
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -i
```

重置后同步更新 `docker-stack/.env` 中对应变量并重新部署 Kibana 服务。

### 8. 移除 stack

```bash
docker stack rm es-prod
```

数据仍保留在 `/docker/es/es-prod-stack/` 各 volume 路径，删除前请自行备份。

## 自定义镜像构建

见 `build/Dockerfile`；CI 见 `.github/workflows/docker-image-es.yml`。
