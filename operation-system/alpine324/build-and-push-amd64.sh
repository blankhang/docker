#!/bin/bash

IMAGE_NAME=blankhang/alpine324-amd64

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}
