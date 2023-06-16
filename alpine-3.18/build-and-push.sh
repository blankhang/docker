#!/bin/bash

IMAGE_NAME=blankhang/alpine-3.18:arm64v8

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}