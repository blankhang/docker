#!/bin/bash

IMAGE_NAME=blankhang/centos7:openjdk17-arm64v8

docker build -t ${IMAGE_NAME} .
docker push ${IMAGE_NAME}