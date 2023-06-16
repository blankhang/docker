#!/bin/bash

docker manifest create blankhang/ubuntu2204:openjdk8 \
blankhang/ubuntu2204:openjdk8-amd64 \
blankhang/ubuntu2204:openjdk8-arm64v8

docker manifest push blankhang/ubuntu2204:openjdk8