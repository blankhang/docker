#!/bin/bash

IMAGE_NAME=blankhang/ubuntu22404:openjdk25

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}