#!/bin/bash -e

docker image build -t blankhang/rabbitmq:4.2.5-management

docker push blankhang/rabbitmq:4.2.5-management
