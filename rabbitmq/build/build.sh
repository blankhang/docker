#!/bin/bash -e
docker image build -t blankhang/rabbitmq:3.8.4-management .
docker push blankhang/rabbitmq:3.8.4-management