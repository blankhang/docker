#!/bin/bash -e

docker image build -t blankhang/rabbitmq:3.9-management .

docker push blankhang/rabbitmq:3.9-management