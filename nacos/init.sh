#!/bin/bash
# create init.d logs directory
mkdir -p /docker/nacos/{init.d,logs}

# create nacos's custom.properties file
cat << 'EOF' > /docker/nacos/init.d/custom.properties
#spring.security.enabled=false
#management.security=false
#security.basic.enabled=false
#nacos.security.ignore.urls=/**
#management.metrics.export.elastic.host=http://localhost:9200
# metrics for prometheus
management.endpoints.web.exposure.include=*

# metrics for elastic search
#management.metrics.export.elastic.enabled=false
#management.metrics.export.elastic.host=http://localhost:9200

# metrics for influx
#management.metrics.export.influx.enabled=false
#management.metrics.export.influx.db=springboot
#management.metrics.export.influx.uri=http://localhost:8086
#management.metrics.export.influx.auto-create-db=true
#management.metrics.export.influx.consistency=one
#management.metrics.export.influx.compressed=true
EOF

#create nacos docker-compose.yml
cat << 'EOF' > /docker/nacos/docker-compose.yml
version: "2"
services:
  nacos:
    image: nacos/nacos-server:2.0.3
    restart: always
    container_name: nacos
    environment:
      PREFER_HOST_MODE: hostname
      MODE: standalone
      SPRING_DATASOURCE_PLATFORM: mysql
      MYSQL_SERVICE_HOST: mysql
      MYSQL_SERVICE_PORT: 3306
      MYSQL_SERVICE_USER: root
      MYSQL_SERVICE_PASSWORD: 123456
      MYSQL_SERVICE_DB_NAME: ry-config
      MYSQL_SERVICE_DB_PARAM: characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false
    volumes:
      - /docker/nacos/logs/:/home/nacos/logs
      - /docker/nacos/init.d/custom.properties:/home/nacos/init.d/custom.properties
    ports:
      - "8848:8848"
      - "9848:9848"
      - "9555:9555"

networks:
  default:
    external:
      name: mysql_default
EOF

echo -e "\033[36m init success \033[0m"
echo "now you can run start.sh to start nacos"