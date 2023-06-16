#!/bin/bash

docker manifest create blankhang/ubuntu2204 \
blankhang/ubuntu2204amd64 \
blankhang/ubuntu2204arm64v8

docker manifest push blankhang/ubuntu2204