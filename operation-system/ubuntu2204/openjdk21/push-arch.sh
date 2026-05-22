#!/bin/bash

docker manifest create blankhang/ubuntu2204:openjdk21 \
blankhang/ubuntu2204:openjdk21-amd64 \
blankhang/ubuntu2204:openjdk21-arm64v8

docker manifest push blankhang/ubuntu2204:openjdk21