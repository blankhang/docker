#!/bin/bash

docker manifest create blankhang/ubuntu2404:openjdk17 \
blankhang/ubuntu2404:openjdk17-amd64 \
blankhang/ubuntu2404:openjdk17-arm64v8

docker manifest push blankhang/ubuntu2404:openjdk17