# docker redis

### 所有文件将会创建到 /docker/rabbitmq 目录中
docker-compose.yml 为3台rabbitmq 伪集群版
stack/rabbitmq-stack.yml 为 docker swarm 集群版
docker-compose-standalone.yml 为单机版

```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  conf.d data
sh init.sh

# 启动
sh start.sh

# 或
docker-compose -f /docker/rabbitmq/docker-compose.yml up -d

# 重启
docker-compose -f /docker/rabbitmq/docker-compose.yml restart

# 停止
docker-compose -f /docker/rabbitmq/docker-compose.yml down
```
---
RabbitMQ 是一款开源的消息代理软件，它使用 AMQP（高级消息队列协议）来传输和存储消息。RabbitMQ 提供了一个可靠、灵活和可扩展的平台，用于构建分布式应用程序和微服务架构。

在 RabbitMQ 中，消息是发布到虚拟目标称为交换机（exchange）的 AMQP 实体上，然后路由到绑定到该交换机的队列中。消费者订阅队列并接收消息。RabbitMQ 的消息传递模型可以使用不同类型的交换机和绑定来满足各种消息路由需求。

RabbitMQ 是使用 Erlang 语言编写的，因此它具有优秀的性能和可靠性，并且可以在多个操作系统和语言之间进行交互。RabbitMQ 还提供了一组丰富的社区和企业支持工具，使得它成为构建应用程序和服务的首选消息代理之一。

除了 AMQP 协议外，RabbitMQ 还支持其他一些标准的消息传递协议，如 STOMP（可扩展文本协议）、MQTT（轻量级消息传输协议）和 HTTP（超文本传输协议）。您可以根据实际需求选择适合的协议，或者使用多种协议同时使用 RabbitMQ。

总而言之，RabbitMQ 是一款功能丰富、可靠、灵活和高性能的消息代理软件，已经被广泛应用于各种领域，如金融、电信、物联网等。

---
在 RabbitMQ 中，不同的端口用于不同的功能。  
以下是 RabbitMQ 中常用端口的作用：
- `4369` 端口：Erlang 分布式节点间通信端口，也称为 epmd（Erlang Port Mapper Daemon）端口。Erlang 节点使用此端口进行发现和连接。
- `5671` `5672` 端口：AMQP 协议端口，用于 RabbitMQ 的客户端连接和消息传输。5671 端口使用 TLS/SSL 加密连接，5672 端口不使用加密连接。默认情况下，RabbitMQ 会在这两个端口上侦听 AMQP 协议的传入连接请求。
- `15671` `15672` 端口：HTTP 协议端口，用于 RabbitMQ 的 Web 管理控制台。15671 端口使用 TLS/SSL 加密连接，15672 端口不使用加密连接。通过 Web 控制台，您可以查看 RabbitMQ 的状态、配置和性能指标，并管理队列、交换机、绑定等对象。
- `15691` `15692` 端口：HTTP 协议端口，用于 RabbitMQ 的 HTTP API。15691 端口使用 TLS/SSL 加密连接，15692 端口不使用加密连接。通过 HTTP API，您可以通过编程方式管理 RabbitMQ 中的对象和数据。例如，您可以使用 API 创建队列、发布消息、订阅消息等。
- `25672` 端口：Erlang 分布式节点间通信端口，也称为 Erlang 分布式锁定内部端口。RabbitMQ 使用此端口在节点之间传输数据和状态信息。