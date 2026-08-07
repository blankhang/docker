# RabbitMQ HAProxy 入口（五节点）

每台 Swarm 节点跑一份 HAProxy（`host` 发布端口），后端负载到全部 `rabbit-sz1`…`rabbit-sz5`。  
Android 等只能配置单一 `host:port` 的客户端：域名解析到 5 个节点 IP，端口统一用 **19100**。

| 端口 | 用途 |
|------|------|
| **19100** | AMQP 统一入口 → 各节点宿主机 `:19101`…`:19105` |
| **19110** | Management 统一入口 → 各节点宿主机 `:19111`…`:19115` |
| **19108** | 健康检查：`GET /health`（无可用 AMQP 后端时 503） |
| **19109** | HAProxy stats：`http://<节点>:19109/stats` |

后端与 nginx `rabbitmq.sz.conf` 同口径：直连内网 IP（sz1–3 `172.29.240.103–105`，sz4–5 `172.29.238.1–2`）的 host 发布端口，**不走** overlay 服务名/`rabbit-szN:5672`。节点 IP 变更时需同步改 `conf/haproxy.cfg`。Swarm config 名：`haproxy_cfg_v4`。

本 stack **不依赖** `rabbitmq-prod` 网络；自建 `hap-egress` overlay 仅供容器出站访问宿主机内网 IP。对外监听仍是 `ports.mode: host`。

独立 stack，不改动 RabbitMQ 服务：

```bash
# manager 上
mkdir -p /docker/rabbitmq/rabbitmq-haproxy-stack
# 拷贝本目录 rabbitmq-haproxy-stack.yml 与 conf/haproxy.cfg

# 五机需有镜像 haproxy:3.4.3-alpine
docker stack deploy --resolve-image never \
  -c rabbitmq-haproxy-stack.yml rabbitmq-haproxy
```

客户端示例：`amqp://user:pass@mq.example.com:19100/`（A 记录指向 sz-1…5 的 IP）。
