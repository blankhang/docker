# docker rabbitmq

### 所有文件将会创建到 /docker/rabbitmq 目录中
请参考 docker-compose 目录 与 stack 目录中 README.md  
java / bash 为 旧配置sha256 的 密码加密


---
### Spring Boot 应用连接 RabbitMQ 集群配置
```yaml
spring.rabbitmq.addresses=node1:5672,node2:5672,node3:5672
spring.rabbitmq.username=blankhang
spring.rabbitmq.password=kbfJ4o8%cGmnrVw**Wtk
```