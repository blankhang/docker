# RabbitMQ 4.3.4 Docker Stack

SZ 生产拓扑：**5 节点一次部署**。从 0 到 1 完整步骤见上级 [`../README.md`](../README.md)。

```bash
# 在 manager 上（目录对齐 /docker/rabbitmq/rabbitmq-prod-stack）
cp rabbitmq_erlang_cookie.txt.example rabbitmq_erlang_cookie.txt   # 改成随机 cookie
# 编辑 rabbitmq-prod.conf 中的账号密码

# 五机各自准备 data-rabbitmq-N（见 scripts/prepare-dirs.sh）
docker stack deploy --resolve-image never -c rabbitmq-stack.yml rabbitmq-prod-stack
```

镜像：`blankhang/rabbitmq:4.3.4-management` · config 名：`rabbitmq_config_v434_5n`
