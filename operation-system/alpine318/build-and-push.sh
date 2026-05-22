#!/bin/bash

IMAGE_NAME=blankhang/alpine318-arm64v8

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}