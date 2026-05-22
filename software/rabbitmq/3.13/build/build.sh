#!/bin/bash -e

docker image build -t blankhang/rabbitmq:3.13-management .

docker push blankhang/rabbitmq:3.13-management