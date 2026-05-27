#!/bin/bash

IMAGE_NAME=blankhang/ubuntu2404

docker build -t ${IMAGE_NAME} .
#docker push ${IMAGE_NAME}