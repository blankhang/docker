#!/bin/bash

echo -e "\033[36m creating rabbitmq local data store directory \033[0m"
# create rabbitmq local data store directory
mkdir  -p /docker/rabbitmq/{conf,data}
chmod 755 /docker/rabbitmq/{conf,data}

echo -e "\033[36m creating rabbimtq.conf \033[0m"
# create rabbimtq.conf
cat << 'EOF' > /docker/mysql/conf/my.cnf
loopback_users.guest = false
listeners.tcp.default = 5672
management.listener.port = 15672
hipe_compile = false
default_user = blankhang
default_pass = kbfJ4o8%cGmnrVw**Wtk
cluster_keepalive_interval = 10000
mnesia_table_loading_retry_timeout = 15000
mnesia_table_loading_retry_limit = 10
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
cluster_formation.classic_config.nodes.1 = rabbit1@rabbit1
cluster_formation.classic_config.nodes.2 = rabbit2@rabbit2
cluster_formation.classic_config.nodes.3 = rabbit3@rabbit3
EOF

# create haproxy.cfg
echo -e "\033[36m creating haproxy.cfg \033[0m"
cat << 'EOF' > /docker/rabbitmq/conf/haproxy.cfg
global
    #日志输出配置，所有日志都记录在本机，通过local0输出
    log 127.0.0.1   local0
    log 127.0.0.1   local1 notice
    #全局最大连接数
    maxconn      4096

defaults
        #应用全局的日志配置
        log global
        #默认的模式mode{tcp|http|health}
        #tcp是4层，http是7层，health只返回OK
        mode tcp
        # 按最少连接负载均衡
        balance leastconn
        #日志类别tcplog
        option tcplog
        #不记录健康检查日志信息
        option dontlognull
        #3次失败则认为服务不可用
        retries 3
        #每个进程可用的最大连接数
        maxconn 1000
        #连接超时
        timeout connect 10s
        #客户端超时
        timeout client 60s
        #服务端超时
        timeout server 60s

# 代理 rabbimtq 负载均衡
listen rabbitmq
    bind *:35671
    #配置TCP模式
    mode tcp
    #加权轮询
    balance roundrobin
    #RabbitMQ集群节点配置,rabbit1~rabbit3为RabbitMQ集群节点ip地址
    server rabbit1  rabbit1:5672  check inter 5s rise 2 fall 3
    server rabbit2  rabbit2:5672  check inter 5s rise 2 fall 3
    server rabbit3  rabbit3:5672  check inter 5s rise 2 fall 3

    # weight - 调节服务器的负重
    # check - 允许对该服务器进行健康检查
    # inter - 设置连续的两次健康检查之间的时间，单位为毫秒(ms)，默认值 2000(ms)
    # rise - 指定多少次连续成功的健康检查后，可认定该服务器处于可操作状态，默认值 2
    # fall - 指定多少次不成功的健康检查后，认为服务器为当掉状态，默认值 3
    # maxconn - 指定可被发送到该服务器的最大并发连接数

#代理 rabbimtq 管理后台ui
listen rabbitmq-ui
    bind *:35672
    mode http
    balance source
    server rabbit1  rabbit1:15672  check
    server rabbit2  rabbit2:15672  check
    server rabbit3  rabbit3:15672  check

#haproxy状态监控
listen stats
  bind *:35673
  mode http
  stats enable
  stats hide-version
  #stats realm Haproxy\ Statistics
  #设置haproxy监控地址为http://storlead.com:35673/
  stats uri /
  #haproxy监控 访问账号密码为 blankhang:haproxy
  stats auth blankhang:haproxy
EOF
echo -e "\033[36m creating rabbitmq docker-compose.yml \033[0m"
# create rabbitmq docker-compose.yml
cat << 'EOF' > /docker/rabbitmq/docker-compose.yml
version: "3.7"
services:
  rabbit1:
    image: rabbitmq:3-management
    hostname: rabbit1
    healthcheck:
      test: curl -s https://localhost:15672 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    environment:
      RABBITMQ_ERLANG_COOKIE: "rabbitmq-cluster-cookie"
      RABBITMQ_NODENAME: rabbit1
    volumes:
      - /docker/rabbitmq/data:/var/lib/rabbitmq
      - /docker/rabbitmq/conf/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
    ports:
      - "5671:5671"
      - "5672:5672"
      - "15671:15671"
      - "15672:15672"
      - "25672:25672"
    networks:
      - rabbitmq-cluster

  rabbit2:
    image: rabbitmq:3-management
    hostname: rabbit2
    healthcheck:
      test: curl -s https://localhost:15672 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    environment:
      RABBITMQ_ERLANG_COOKIE: "rabbitmq-cluster-cookie"
      RABBITMQ_NODENAME: rabbit2
    volumes:
      - /docker/rabbitmq/data:/var/lib/rabbitmq
      - /docker/rabbitmq/conf/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
    networks:
      - rabbitmq-cluster

  rabbit3:
    image: rabbitmq:3-management
    hostname: rabbit3
    healthcheck:
      test: curl -s https://localhost:15672 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    environment:
      RABBITMQ_ERLANG_COOKIE: "rabbitmq-cluster-cookie"
      RABBITMQ_NODENAME: rabbit3
    volumes:
      - /docker/rabbitmq/data:/var/lib/rabbitmq
      - /docker/rabbitmq/conf/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
    networks:
      - rabbitmq-cluster

  haproxy:
    image: haproxy
    hostname: haproxy
    healthcheck:
      test: curl -s https://localhost:35673 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    deploy:
      replicas: 1
      update_config:
        parallelism: 1
        delay: 1m
      restart_policy:
        condition: on-failure
    environment:
      TZ: "Asia/Shanghai"
    ports:
      - 35671:35671 # RabbitMQ load balance AMQP port
      - 35672:35672 # RabbitMQ management ui http port
      - 35673:35673 # haproyx stats http port
    volumes:
      - /docker/rabbitmq/conf/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg
    networks:
      - rabbitmq-cluster
    depends_on:
      - rabbit1
      - rabbit2
      - rabbit3

networks:
  rabbitmq-cluster:
#    driver: overlay
EOF

echo -e "init \e[92m success"
echo -e "now \e[93m you can run start.sh to start rabbitmq cluster \033[0m"