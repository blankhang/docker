#!/bin/bash

docker manifest create blankhang/alpine324 \
blankhang/alpine324-amd64 \
blankhang/alpine324-arm64v8

docker manifest push blankhang/alpine324
