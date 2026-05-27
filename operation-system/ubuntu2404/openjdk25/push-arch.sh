#!/bin/bash

docker manifest create blankhang/ubuntu2404:openjdk25 \
blankhang/ubuntu2404:openjdk25-amd64 \
blankhang/ubuntu2404:openjdk25-arm64v8

docker manifest push blankhang/ubuntu2404:openjdk25