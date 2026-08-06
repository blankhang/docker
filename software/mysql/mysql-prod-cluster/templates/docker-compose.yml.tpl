# 按节点复制为 /docker/mysql/mysql-prod-cluster/docker-compose.yml
# 仅改 hostname、MYSQL_HOST、以及 Router 的 MEMBERS（扩容后改为 5）

services:
  mysql:
    image: mysql:8.4
    container_name: mysql8-prod-cluster
    restart: always
    hostname: sz-N
    network_mode: host

    cap_add:
      - SYS_NICE

    environment:
      TZ: Asia/Shanghai
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      MYSQL_ROOT_HOST: "%"
      MYSQL_DATABASE: test
      MYSQL_USER: blank
      MYSQL_PASSWORD: "${MYSQL_USER_PASSWORD}"

    volumes:
      - ./conf/my.cnf:/etc/mysql/conf.d/my.cnf:ro
      - ./data:/var/lib/mysql
      - ./log:/var/log/mysql
      - /etc/localtime:/etc/localtime:ro

    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-P", "55511", "-u", "blank", "-p${MYSQL_USER_PASSWORD}"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 30s

  mysql-router:
    image: container-registry.oracle.com/mysql/community-router:8.4
    container_name: mysql-prod-router
    restart: always

    environment:
      MYSQL_HOST: "sz-N"
      MYSQL_PORT: "55511"
      MYSQL_USER: "mysqlrouter"
      MYSQL_PASSWORD: "${MYSQL_ROUTER_PASSWORD}"
      # 扩容到 5 节点后改为 "5"
      MYSQL_INNODB_CLUSTER_MEMBERS: "5"
      MYSQL_CREATE_ROUTER_USER: "0"

    volumes:
      - ./router:/tmp/mysqlrouter

    ports:
      - "55546:6446"
      - "55547:6447"

    healthcheck:
      # 探测 Router 读写/只读端口是否在听（镜像内无 mysqladmin）
      test: ["CMD", "bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/6446 && exec 4<>/dev/tcp/127.0.0.1/6447"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s

    depends_on:
      - mysql
