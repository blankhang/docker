# Elasticsearch 9.3.3 Swarm Stack（3 节点 + Kibana）

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
docker stack deploy --env-file .env -c es-stack.yml es-prod
```

重置密码：

```bash
docker exec -it {es containerid} /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -i
docker exec -it {es containerid} /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i
```
