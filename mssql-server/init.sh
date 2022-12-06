#!/bin/bash

# create mssql-server local data store directory
mkdir  -p /docker/mssql-server/{data,log,secrets}
chmod 777 /docker/mssql-server/{data,log,secrets}

# create mssql-server's .env file
# mssql-server password please change it before use on prod env
cat << 'EOF' > /docker/mssql-server/.env
DB_PASSWORD=pleaseChangeMe
EOF
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
      - 1433:1433

EOF

echo 'please change /docker/mssql-server/.env'
echo -e "\033[31m DB_PASSWORD \033[0m"

echo 'before run into prod environment'
echo 'the default SA_PASSWORD is'
echo -e "\033[36m 9ufs6WpSYhZ*!s6RJBQ3 \033[0m"