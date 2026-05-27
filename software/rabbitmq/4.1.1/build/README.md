## docker rabbitmq build 
集成延迟死信队列插件  
且默认启用如下插件  
- rabbitmq_management,
- rabbitmq_consistent_hash_exchange,
- rabbitmq_delayed_message_exchange,
- rabbitmq_mqtt,
- rabbitmq_prometheus,
- rabbitmq_peer_discovery_consul,
- rabbitmq_federation,
- rabbitmq_federation_management,
- rabbitmq_shovel,
- rabbitmq_shovel_management

```bash
docker image build -t blankhang/rabbitmq:4.1.1-management .
```
---
