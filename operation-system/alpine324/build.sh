#!/bin/bash

IMAGE_NAME=blankhang/alpine324:glibc-2.35-r1

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}
