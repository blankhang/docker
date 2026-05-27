#!/bin/bash -e

docker image build -t blankhang/redis:8.8.0 .

docker push blankhang/redis:8.8.0
