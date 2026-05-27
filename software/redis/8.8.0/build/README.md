# blankhang/redis:8.8.0

基于官方 `redis:8.8.0-alpine`，叠加自定义 `redis.conf`（含 keyspace 通知等）。

```bash
docker image build -t blankhang/redis:8.8.0 .
docker push blankhang/redis:8.8.0
```

GitHub Actions：`.github/workflows/docker-image-redis.yml`（`IMAGE_VERSION: 8.8.0`）。
