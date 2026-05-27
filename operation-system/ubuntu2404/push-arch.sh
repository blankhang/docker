#!/bin/bash

docker manifest create blankhang/ubuntu2404 \
blankhang/ubuntu2404amd64 \
blankhang/ubuntu2404arm64v8

docker manifest push blankhang/ubuntu2404