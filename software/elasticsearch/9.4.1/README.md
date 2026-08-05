# Elasticsearch / Kibana 9.4.1

| 目录 | 用途 |
|------|------|
| `build/` | 自定义镜像（含 IK 分词） |
| `docker-compose/` | 单机 Compose 开发/测试 |
| `docker-stack/` | Swarm 多节点生产栈 |

## Docker Compose（单机）

```shell
cd docker-compose

mkdir -p data-kibana data-elasticsearch
sudo chown -R 1000:1000 data-*

# 修改 .env 中的 ELASTIC_PASSWORD、KIBANA_PASSWORD
docker compose up -d
```

## Docker Stack（Swarm 生产）

多节点 Elasticsearch 集群 + 1 个 Kibana，镜像为 `blankhang/elasticsearch:9.4.1`（含 IK）与官方 `kibana:9.4.1`。

仓库默认 `es-stack.yml` 为 **3 节点**；可按需扩到 5 节点（见下文「无损扩容」）。

| 服务 | 节点约束（示例） | 发布端口 | 说明 |
|------|------------------|----------|------|
| es-node1 | `xhc-sz-1` | 19201→9200 | 与 Kibana 同机（可改） |
| es-node2 | `xhc-sz-2` | 19202→9200 | |
| es-node3 | `xhc-sz-3` | 19203→9200 | |
| es-node4 | `xhc-sz-4` | 19204→9200 | 扩容时新增 |
| es-node5 | `xhc-sz-5` | 19205→9200 | 扩容时新增 |
| kibana | `xhc-sz-1` | 15601→5601 | 连接各 `es-node*:9200` |

宿主机数据目录以 `es-stack.yml` 中 `volumes` 为准（仓库示例为 `/docker/es/es-prod-stack/`；生产若用 `/docker/es-stack/` 请改 yml 保持一致）。

节点间 **transport TLS** 使用同一份 PKCS#12（keystore + truststore），文件为 `docker-stack/conf/elastic-certificates_p12`。

---

### 1. 前置条件

- 目标主机已加入 **Docker Swarm**，hostname 与 `es-stack.yml` 里 `deploy.placement.constraints` 一致。
- 已构建/拉取 `blankhang/elasticsearch:9.4.1`。
- 在 **manager** 上准备好 `docker-stack/`（含 `.env`、`conf/`）。

### 2. 生成 CA 与集群证书（必做）

全节点共用 **一份** p12。SAN 必须包含所有 `node.name`（`discovery` / `network.publish_host` 用的服务名），否则新节点会报 `certificate_unknown` 无法入群。

在 manager 上执行（目录可写；容器内 ES 默认 uid 1000，宿主机目录若属 root 需加 `--user root`）：

```bash
cd docker-stack/conf
# 生产机若证书放在 /docker/es-stack/conf，则 cd 到该目录即可

# 1) 生成 CA（交互询问密码；可直接回车使用空密码）
# 注意：不要加 -w /cwd，否则会找不到镜像内的 bin/
docker run --rm -it --user root -v "$PWD:/cwd" blankhang/elasticsearch:9.4.1 \
  /usr/share/elasticsearch/bin/elasticsearch-certutil ca \
    --out /cwd/elastic-stack-ca.p12

# 2) 用 CA 签发集群证书（DNS 写上当前全部节点名）
# 3 节点示例：
docker run --rm -it --user root -v "$PWD:/cwd" blankhang/elasticsearch:9.4.1 \
  /usr/share/elasticsearch/bin/elasticsearch-certutil cert \
    --ca /cwd/elastic-stack-ca.p12 \
    --name es-cluster \
    --dns es-node1,es-node2,es-node3 \
    --out /cwd/elastic-certificates.p12

# 5 节点则改为：
#   --dns es-node1,es-node2,es-node3,es-node4,es-node5
```

将产出拷为 Swarm 使用的文件名（与 `es-stack.yml` 中 `configs.file` 一致）：

```bash
cp -a elastic-certificates.p12 elastic-certificates_p12
# 妥善备份 elastic-stack-ca.p12 与 elastic-certificates.p12（加节点时需用同一 CA 重签）
```

校验（空密码须用 `-storepass ''`，交互回车常会误显示 `chain length: 0`）：

```bash
keytool -list -v -keystore elastic-certificates_p12 -storetype PKCS12 -storepass '' \
  | grep -E 'Alias name:|Owner:|DNSName:|Valid from'
```

应能看到 `DNSName: es-node1` 等，以及 `ca` / 节点别名两条 entry。

若 p12 **设置了密码**，在每个 es 节点的 `environment` 中增加：

```yaml
- xpack.security.transport.ssl.keystore.password=你的密码
- xpack.security.transport.ssl.truststore.password=你的密码
```

空密码则无需这两行。当前 yml 典型配置：

```yaml
- xpack.security.transport.ssl.enabled=true
- xpack.security.transport.ssl.keystore.path=/usr/share/elasticsearch/config/certs/elastic-certificates.p12
- xpack.security.transport.ssl.truststore.path=/usr/share/elasticsearch/config/certs/elastic-certificates.p12
```

#### 更新 / 轮换证书（Swarm config 不可变）

修改 `conf/elastic-certificates_p12` 后，递增 `docker-stack/.env` 中的 `ELASTIC_CERT_CONFIG_VERSION`（如 `v1` → `v2`），再 `docker stack deploy`。  
`es-stack.yml` 通过 `name: elastic_cert_p12_${ELASTIC_CERT_CONFIG_VERSION}` 挂载新内容。

**所有节点必须同时换成同一份新证书**（新旧 CA 不可混用）。建议低峰滚动；`update_config` 为 `stop-first`。

若生产使用 `external: true` 的 config，则：

```bash
docker config create elastic-certificates-p12-v2 ./elastic-certificates.p12
# 再改 yml 引用该 external config 后 deploy
```

### 3. 创建数据目录

路径须与 `es-stack.yml` 中 volumes 一致。示例（仓库默认路径）：

```bash
# node-1（含 Kibana）
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node1 \
  /docker/es/es-prod-stack/es-backup \
  /docker/es/es-prod-stack/data-kibana
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node1 \
  /docker/es/es-prod-stack/es-backup \
  /docker/es/es-prod-stack/data-kibana

# node-2 / node-3（扩容时同样准备 node4、node5）
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node2 \
  /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node2 \
  /docker/es/es-prod-stack/es-backup

sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node3 \
  /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node3 \
  /docker/es/es-prod-stack/es-backup
```

常见排错：`invalid mount config for type "bind"` → 目标机上对应数据目录不存在，或 yml 里路径写错（例如 node5 误写成 node4 目录）。

### 4. 配置 `.env`

编辑 `docker-stack/.env`：

| 变量 | 说明 |
|------|------|
| `ELK_VERSION` | 镜像 tag，默认 `9.4.1` |
| `ELASTIC_CERT_CONFIG_VERSION` | 改证书文件后递增，触发新 Swarm config |
| `ELASTIC_PASSWORD` | ES `elastic` 用户密码 |
| `KIBANA_USERNAME` / `KIBANA_PASSWORD` | Kibana 连接 ES（通常为 `kibana_system`） |
| `XPACK_*_ENCRYPTIONKEY` | Kibana 加密密钥（变更会导致已加密对象不可用） |

### 5. 部署

在 Swarm **manager** 上：

```bash
cd docker-stack
set -a && source .env && set +a
docker stack deploy -c es-stack.yml es-prod
```

> `docker stack deploy` **没有** `--env-file`。`.env` 仅用于 compose 插值，须先 `source`，或：
>
> `docker compose --env-file .env -f es-stack.yml config | docker stack deploy -c - es-prod`

查看状态：

```bash
docker stack services es-prod
docker stack ps es-prod
docker service logs es-prod_es-node1 -f
```

### 6. 首次集群初始化后

首次形成集群时需要 `cluster.initial_master_nodes`。**集群已稳定后必须注释掉**并重新 deploy，避免后续重启被当成 bootstrap。

新加入的节点 **永远不要** 写 `cluster.initial_master_nodes`。

### 7. 无损扩容（如 3 → 5）

优先在现有集群加节点，不必新建集群再迁移。

1. 新机加入 Swarm，建好数据目录并 `chown 1000:1000`。
2. **用同一 CA** 重签 p12，`--dns` 包含全部新旧节点名；替换 `conf/elastic-certificates_p12` 并递增 `ELASTIC_CERT_CONFIG_VERSION`（或更新 external config）。
3. 在 `es-stack.yml` 增加 `es-node4` / `es-node5`（placement、volume、端口）；**新节点不写** `initial_master_nodes`。
4. 所有节点更新 `discovery.seed_hosts`（及 Kibana `ELASTICSEARCH_HOSTS`）。
5. `docker stack deploy`；建议一次加一个节点，等 `_cat/nodes` 出现且 health 正常再加下一个。
6. 确认：

```bash
curl -u elastic:"$ELASTIC_PASSWORD" 'http://127.0.0.1:19201/_cat/nodes?v'
curl -u elastic:"$ELASTIC_PASSWORD" 'http://127.0.0.1:19201/_cluster/health?pretty'
```

分片会自动再均衡。新旧证书 CA 不同时不可混挂。

临时规避主机名校验（仅作过渡，仍建议重签含全节点 SAN 的证书）：

```yaml
- xpack.security.transport.ssl.verification_mode=certificate
```

### 8. 更新 stack / 升级版本

改 `es-stack.yml` 或 `.env` 后再次 `docker stack deploy`（滚动，`stop-first`）。

升级镜像：先构建/拉取新 tag，改 `ELK_VERSION` 后部署。

### 9. 重置密码

```bash
docker exec -it $(docker ps -q -f name=es-prod_es-node1) \
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i

docker exec -it $(docker ps -q -f name=es-prod_es-node1) \
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -i
```

重置后同步 `.env` 并重新部署 Kibana。

### 10. 移除 stack

```bash
docker stack rm es-prod
```

数据仍在宿主机 volume 路径，删除前请自行备份。

---

## 自定义镜像构建

见 `build/Dockerfile`；CI 见 `.github/workflows/docker-image-es.yml`。

更细的 Swarm 操作说明见 [`docker-stack/README.md`](docker-stack/README.md)。
