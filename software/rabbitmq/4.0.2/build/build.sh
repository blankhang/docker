#!/bin/bash -e

docker image build -t blankhang/rabbitmq:4.0.2-management .

docker push blankhang/rabbitmq:4.0.2-management