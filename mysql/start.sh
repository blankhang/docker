#!/bin/bash

# start mysql docker
docker-compose -f /docker/mysql/docker-compose.yml up -d

echo 'mysql start success'