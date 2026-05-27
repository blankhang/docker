## docker swarm 集群版 rabbitmq 服务
服务将会在3台节点上运行  
3台节点 hostname 分别为 vm-ubuntu-12 / vm-ubuntu-13 / vm-ubuntu-14 的服务器  
在master管理节点运行
```bash
docker stack deploy -c rabbitmq-stack.yml rabbitmq
```
---
