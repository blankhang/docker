#!/bin/bash -e

docker image build -t blankhang/rabbitmq:4.1.0-management-250425 .

docker push blankhang/rabbitmq:4.1.0-management-250425