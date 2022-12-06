#!/bin/bash

IMAGE_NAME=blankhang/alpine-3.17:glibc-2.32-r0

docker build -t ${IMAGE_NAME} .
#docker push ${IMAGE_NAME}