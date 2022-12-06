#!/bin/bash
docker-compose -f /docker/nacos/docker-compose.yml up -d
echo -e "\033[36m nacos server start success \033[0m"