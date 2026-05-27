#!/bin/bash

IMAGE_NAME=blankhang/ubuntu2404-arm64v8

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}