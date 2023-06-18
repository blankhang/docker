#!/bin/bash -e

docker image build -t blankhang/rabbitmq:3.12-management .

docker push blankhang/rabbitmq:3.12-management