# Elasticsearch / Kibana 9.3.3

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

## 自定义镜像构建

见 `build/Dockerfile`；CI 见 `.github/workflows/docker-image-es.yml`。
