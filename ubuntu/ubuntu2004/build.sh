#!/bin/bash

IMAGE_NAME=blankhang/ubuntu2004:openjdk8

docker build -t ${IMAGE_NAME} .
#docker push ${IMAGE_NAME}