#!/bin/bash

echo -e "\033[36m creating rabbitmq local data store directory \033[0m"
# create rabbitmq local data store directory
mkdir -p /docker/rabbitmq/{conf,data}
chown -R 999:999 /docker/rabbitmq/{conf,data}
chmod 755 /docker/rabbitmq/{conf,data}

echo -e "\033[36m creating rabbimtq.conf \033[0m"
# create rabbimtq.conf
cat << 'EOF' > /docker/rabbimtq/conf/rabbimtq.cnf
loopback_users.guest = false
listeners.tcp.default = 5672
management.listener.port = 15672
hipe_compile = false
default_user = admin
default_pass = admin
cluster_keepalive_interval = 10000
mnesia_table_loading_retry_timeout = 15000
mnesia_table_loading_retry_limit = 10
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
cluster_formation.classic_config.nodes.1 = rabbit1@rabbit1
cluster_formation.classic_config.nodes.2 = rabbit2@rabbit2
cluster_formation.classic_config.nodes.3 = rabbit3@rabbit3
EOF

echo -e "\033[36m creating rabbitmq docker-compose.yml \033[0m"
# create rabbitmq docker-compose.yml
cat << 'EOF' > /docker/rabbitmq/docker-compose.yml
version: "3.9"
services:
  rabbit1:
    image: blankhang/rabbitmq:4.1.1-management
    hostname: rabbit1
    healthcheck:
      test: curl -s https://localhost:15672 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    environment:
      RABBITMQ_ERLANG_COOKIE: "rabbitmq-cluster-cookie"
      RABBITMQ_NODENAME: rabbit1
    configs:
      - source: rabbitmq_conf
        target: /etc/rabbitmq/rabbitmq.conf
    volumes:
      - /docker/rabbitmq/data:/var/lib/rabbitmq
    ports:
      - "15672:15672"
    networks:
      - rabbitmq-compose

  rabbit2:
    image: blankhang/rabbitmq:4.1.1-management
    hostname: rabbit2
    healthcheck:
      test: curl -s https://localhost:15672 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    environment:
      RABBITMQ_ERLANG_COOKIE: "rabbitmq-cluster-cookie"
      RABBITMQ_NODENAME: rabbit2
    configs:
      - source: rabbitmq_conf
        target: /etc/rabbitmq/rabbitmq.conf
    volumes:
      - /docker/rabbitmq/data:/var/lib/rabbitmq
    networks:
      - rabbitmq-compose

  rabbit3:
    image: blankhang/rabbitmq:4.1.1-management
    hostname: rabbit3
    healthcheck:
      test: curl -s https://localhost:15672 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    environment:
      RABBITMQ_ERLANG_COOKIE: "rabbitmq-cluster-cookie"
      RABBITMQ_NODENAME: rabbit3
    configs:
      - source: rabbitmq_conf
        target: /etc/rabbitmq/rabbitmq.conf
    volumes:
      - /docker/rabbitmq/data:/var/lib/rabbitmq
    networks:
      - rabbitmq-compose


configs:
  rabbitmq_conf:
    file: ./conf/rabbitmq.conf

networks:
  rabbitmq-compose:
    driver: bridge
EOF

echo -e "init \e[92m success"
echo -e "now \e[93m you can run start.sh to start rabbitmq cluster \033[0m"
