## arm64/amd64 arch support rabbitmq:3.12-management image with GMT+8 TZ 
## 支持 arm64 amd64 架构的 rabbitmq:3.12-management GMT+8时区的底包镜像 添加启用延迟队列插件
source code at https://github.com/blankhang/docker/tree/master/ubuntu2204

### 基于官方 rabbitmq 3.12.0-management 版本
### 启用如下插件
- rabbitmq_shovel_management
- rabbitmq_federation_management
- rabbitmq_federation
- rabbitmq_peer_discovery_consul
- rabbitmq_peer_discovery_common
- rabbitmq_shovel
- rabbitmq_management
- rabbitmq_web_dispatch
- rabbitmq_management_agent

### how to use 使用方法
```shell
docker pull blankhang/rabbitmq
```

### 所有文件将会创建到 /docker/rabbitmq 目录中
请参考 docker-compose 目录 与 stack 目录中 README.md  
java / bash 为 旧配置sha256 的 密码加密

---
### Spring Boot 应用连接 RabbitMQ 集群配置
```yaml
spring.rabbitmq.addresses=rabbit1:5672,rabbit2:5672,rabbit3:5672
spring.rabbitmq.username=blankhang
spring.rabbitmq.password=blankhang
```