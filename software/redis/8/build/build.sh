#!/bin/bash -e

docker image build -t blankhang/redis:8 .

docker push blankhang/redis:8