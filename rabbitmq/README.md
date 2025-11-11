## arm64/amd64 arch support rabbitmq:3.13-management image with GMT+8 TZ 
## 支持 arm64 amd64 架构的 rabbitmq:3.13-management GMT+8时区的底包镜像 添加启用延迟队列插件
source code at https://github.com/blankhang/docker/tree/master/ubuntu2204

### 基于官方 rabbitmq 4.1.1-management alpine 版本
### 默认启用如下插件
### By default, the following plug-ins are enabled
- rabbitmq_management
- rabbitmq_management_agent
- rabbitmq_consistent_hash_exchange
- rabbitmq_delayed_message_exchange
- rabbitmq_mqtt
- rabbitmq_prometheus
- rabbitmq_peer_discovery_consul
- rabbitmq_peer_discovery_common
- rabbitmq_federation
- rabbitmq_federation_management
- rabbitmq_shovel
- rabbitmq_shovel_management
- rabbitmq_web_dispatch

### how to use 使用方法
```shell
docker pull blankhang/rabbitmq
```

### 常用命令 在 rabbitmq 容器内执行
```shell
#列出已安装的插件 前面 [E] 表示已启用 [e] 表示隐式启用
rabbitmq-plugins list

[  ] rabbitmq_amqp1_0                  3.13.0
[  ] rabbitmq_auth_backend_cache       3.13.0
[  ] rabbitmq_auth_backend_http        3.13.0
[  ] rabbitmq_auth_backend_ldap        3.13.0
[  ] rabbitmq_auth_backend_oauth2      3.13.0
[  ] rabbitmq_auth_mechanism_ssl       3.13.0
[E ] rabbitmq_consistent_hash_exchange 3.13.0
[E ] rabbitmq_delayed_message_exchange 3.13.0
[  ] rabbitmq_event_exchange           3.13.0
[E ] rabbitmq_federation               3.13.0
[E ] rabbitmq_federation_management    3.13.0
[  ] rabbitmq_jms_topic_exchange       3.13.0
[E ] rabbitmq_management               3.13.0
[e ] rabbitmq_management_agent         3.13.0
[E ] rabbitmq_mqtt                     3.13.0
[  ] rabbitmq_peer_discovery_aws       3.13.0
[e ] rabbitmq_peer_discovery_common    3.13.0
[E ] rabbitmq_peer_discovery_consul    3.13.0
[  ] rabbitmq_peer_discovery_etcd      3.13.0
[  ] rabbitmq_peer_discovery_k8s       3.13.0
[E ] rabbitmq_prometheus               3.13.0
[  ] rabbitmq_random_exchange          3.13.0
[  ] rabbitmq_recent_history_exchange  3.13.0
[  ] rabbitmq_sharding                 3.13.0
[E ] rabbitmq_shovel                   3.13.0
[E ] rabbitmq_shovel_management        3.13.0
[  ] rabbitmq_stomp                    3.13.0
[  ] rabbitmq_stream                   3.13.0
[  ] rabbitmq_stream_management        3.13.0
[  ] rabbitmq_top                      3.13.0
[  ] rabbitmq_tracing                  3.13.0
[  ] rabbitmq_trust_store              3.13.0
[e ] rabbitmq_web_dispatch             3.13.0
[  ] rabbitmq_web_mqtt                 3.13.0
[  ] rabbitmq_web_mqtt_examples        3.13.0
[  ] rabbitmq_web_stomp                3.13.0
[  ] rabbitmq_web_stomp_examples       3.13.0

# 启用插件
rabbitmq-plugins enable <plugin-name>
# 启用 mqtt 插件
rabbitmq-plugins enable rabbitmq_mqtt
# 由于 MQTT 插件是动态启用的，因此 MQTT 插件定义的功能标志将被禁用。启用所有功能标志，包括功能标志 mqtt_v5：
rabbitmqctl enable_feature_flag all

# 禁用插件
rabbitmq-plugins disable <plugin-name>
# 禁用 mqtt 插件
rabbitmq-plugins disable rabbitmq_mqtt
```


### 所有文件将会创建到 /docker/rabbitmq 目录中
请参考 docker-compose 目录 与 stack 目录中 README.md  
java / bash 为 旧配置sha256 的 密码加密

---
### Spring Boot 应用连接 RabbitMQ 集群配置
```yaml
spring.rabbitmq.addresses=rabbit1:5672,rabbit2:5672,rabbit3:5672
spring.rabbitmq.username=admin
spring.rabbitmq.password=admin
```