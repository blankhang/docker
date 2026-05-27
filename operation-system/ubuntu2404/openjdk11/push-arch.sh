#!/bin/bash

docker manifest create blankhang/ubuntu2404:openjdk11 \
blankhang/ubuntu2404:openjdk11-amd64 \
blankhang/ubuntu2404:openjdk11-arm64v8

docker manifest push blankhang/ubuntu2404:openjdk11