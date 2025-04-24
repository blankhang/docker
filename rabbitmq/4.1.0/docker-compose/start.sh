#!/bin/bash

# start rabbimtq cluster with haproxy
docker-compose -f /docker/rabbitmq/docker-compose.yml up -d