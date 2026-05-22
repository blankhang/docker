#!/bin/bash -e

docker image build -t blankhang/redis:7 .

docker push blankhang/redis:7