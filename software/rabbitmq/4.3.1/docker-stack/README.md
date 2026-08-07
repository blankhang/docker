# RabbitMQ 4.3.1 Docker Stack

SZ 生产拓扑模板（默认 5 节点）。完整从 0 到 1 / 无损扩容说明见上级 [`../README.md`](../README.md)。

```bash
# 在 manager 上（目录对齐生产 /docker/rabbitmq/rabbitmq-prod-stack）
cp rabbitmq_erlang_cookie.txt.example rabbitmq_erlang_cookie.txt   # 改成随机 cookie
# 编辑 rabbitmq-prod.conf 中的账号密码

docker stack deploy --resolve-image never -c rabbitmq-stack.yml rabbitmq-prod-stack
```
