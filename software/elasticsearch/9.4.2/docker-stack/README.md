# Elasticsearch 9.4.2 Swarm Stack

完整说明（含 **CA / 证书生成**、扩容、排错）见上级 [`../README.md`](../README.md)。

## 证书（deploy 前）

```bash
cd conf   # 或生产机上的证书目录，如 /docker/es-stack/conf

docker run --rm -it --user root -v "$PWD:/cwd" blankhang/elasticsearch:9.4.2 \
  /usr/share/elasticsearch/bin/elasticsearch-certutil ca \
    --out /cwd/elastic-stack-ca.p12

docker run --rm -it --user root -v "$PWD:/cwd" blankhang/elasticsearch:9.4.2 \
  /usr/share/elasticsearch/bin/elasticsearch-certutil cert \
    --ca /cwd/elastic-stack-ca.p12 \
    --name es-cluster \
    --dns es-node1,es-node2,es-node3 \
    --out /cwd/elastic-certificates.p12

cp -a elastic-certificates.p12 elastic-certificates_p12
keytool -list -v -keystore elastic-certificates_p12 -storetype PKCS12 -storepass '' | grep DNSName
```

修改证书后递增 `.env` 中 `ELASTIC_CERT_CONFIG_VERSION` 再 deploy（Swarm config 不可变）。

| 变量 | 文件 |
|------|------|
| `ELASTIC_CERT_CONFIG_VERSION` | `conf/elastic-certificates_p12` |

## 数据目录

路径须与 `es-stack.yml` 的 volumes 一致：

```bash
# node-1
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node1 \
  /docker/es/es-prod-stack/es-backup /docker/es/es-prod-stack/data-kibana
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node1 \
  /docker/es/es-prod-stack/es-backup /docker/es/es-prod-stack/data-kibana

# node-2 / node-3（扩容时同样准备 node4、node5 目录，且勿写错节点名）
sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node2 /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node2 /docker/es/es-prod-stack/es-backup

sudo mkdir -p /docker/es/es-prod-stack/data-elasticsearch-node3 /docker/es/es-prod-stack/es-backup
sudo chown -R 1000:1000 /docker/es/es-prod-stack/data-elasticsearch-node3 /docker/es/es-prod-stack/es-backup
```

## 部署

```bash
cd docker-stack
set -a && source .env && set +a
docker stack deploy -c es-stack.yml es-prod
```

或先渲染：

```bash
docker compose --env-file .env -f es-stack.yml config | docker stack deploy -c - es-prod
```

Kibana 精简项写在 `es-stack.yml` 的 `environment`（**不挂载** `kibana.yml` Swarm config，避免旧 config 残留已删除键导致 FATAL）。`conf/kibana-lean.yml` 仅为注释参考。

若日志仍报 `timelion.ui.enabled`：

```bash
docker service inspect es-prod_kibana --format '{{range .Spec.TaskTemplate.ContainerSpec.Configs}}{{.ConfigName}} {{end}}'
docker exec $(docker ps -q -f name=es-prod_kibana) cat /usr/share/kibana/config/kibana.yml | head -50
```

然后重新 deploy，必要时 `docker service update --force es-prod_kibana`。

## 重置密码

```bash
docker exec -it $(docker ps -q -f name=es-prod_es-node1) \
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -i
docker exec -it $(docker ps -q -f name=es-prod_es-node1) \
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i
```
