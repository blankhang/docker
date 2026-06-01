# Elasticsearch 9.4.2 Swarm Stack（3 节点 + Kibana）

部署前在各节点创建数据目录并授权：

```bash
# node-1
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node1 /docker/es/es-prod-stack/es-backup /docker/es/es-prod-stack/data-kibana
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node1 /docker/es/es-prod-stack/es-backup /docker/es/es-prod-stack/data-kibana

# node-2
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node2 /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node2 /docker/es/es-prod-stack/es-backup

# node-3
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node3 /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node3 /docker/es/es-prod-stack/es-backup
```

密码与版本在 `.env` 中配置（部署前请按环境修改）：

```bash
cd docker-stack
# docker stack deploy 不支持 --env-file（Compose 专有）；先加载 .env 做 ${VAR} 插值
set -a && source .env && set +a
docker stack deploy -c es-stack.yml es-prod
```

或先渲染再部署：

```bash
cd docker-stack
docker compose --env-file .env -f es-stack.yml config | docker stack deploy -c - es-prod
```

Kibana 精简项写在 `es-stack.yml` 的 `environment`（**不挂载** `kibana.yml` Swarm config，避免旧 config 里残留 `timelion.ui.enabled` 导致 FATAL）。`conf/kibana-lean.yml` 仅为注释参考。

若日志仍报 `timelion.ui.enabled`：说明任务还在用旧 config，在 manager 上执行：

```bash
docker service inspect es-prod_kibana --format '{{range .Spec.TaskTemplate.ContainerSpec.Configs}}{{.ConfigName}} {{end}}'
# 不应再出现 kibana_lean_yml_*

docker exec $(docker ps -q -f name=es-prod_kibana) cat /usr/share/kibana/config/kibana.yml | head -50
# 应为镜像默认内容，不含 timelion
```

然后 `set -a && source .env && set +a && docker stack deploy -c es-stack.yml es-prod`，必要时 `docker service update --force es-prod_kibana`。

Swarm `configs` 版本（仅证书）：

| 变量 | 文件 |
|------|------|
| `ELASTIC_CERT_CONFIG_VERSION` | `conf/elastic-certificates_p12` |

重置密码：

```bash
docker exec -it {es containerid} /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -i
docker exec -it {es containerid} /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i
```
