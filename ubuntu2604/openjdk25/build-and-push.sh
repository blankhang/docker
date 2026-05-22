#!/bin/bash

IMAGE_NAME=blankhang/ubuntu2604:openjdk25

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}
