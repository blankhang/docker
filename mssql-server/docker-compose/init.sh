#!/bin/bash

# create mssql-server local data store directory
mkdir  -p /docker/mssql-server/{data,log,secrets}
chmod 777 /docker/mssql-server/{data,log,secrets}

# create mssql-server's docker-compose file
cat << 'EOF' > /docker/mssql-server/docker-compose.yml

version: '3.7'
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2019-latest
    container_name: sqlserver
    restart: always
    # privileged: true
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$$SA_PASSWORD" -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
    environment:
      TZ: "Asia/Shanghai"
      ACCEPT_EULA: "Y"
      SA_PASSWORD: $DB_PASSWORD
      MSSQL_PID: "Developer"
      MSSQL_COLLATION: "Chinese_PRC_CI_AS"
    volumes:
      - "./data:/var/opt/mssql/data"
      - "./log:/var/opt/mssql/log"
      - "./secrets:/var/opt/mssql/secrets"
    ports:
      - 54130:1433

EOF

# start mssql-server docker
docker-compose -c /docker/mssql-server/docker-compose.yml up -d