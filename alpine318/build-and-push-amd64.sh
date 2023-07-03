#!/bin/bash

IMAGE_NAME=blankhang/alpine318:glibc-2.35-r1-amd64

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}