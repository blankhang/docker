#!/bin/bash -e

docker image build -t blankhang/rabbitmq:4.3.1-management

docker push blankhang/rabbitmq:4.3.1-management
