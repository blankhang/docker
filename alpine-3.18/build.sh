#!/bin/bash

IMAGE_NAME=blankhang/alpine-3.18:glibc-2.35-r1

docker build -t ${IMAGE_NAME} .
#docker push ${IMAGE_NAME}