#!/bin/bash

docker manifest create blankhang/ubuntu2604:openjdk25 \
blankhang/ubuntu2604:openjdk25-amd64 \
blankhang/ubuntu2604:openjdk25-arm64v8

docker manifest push blankhang/ubuntu2604:openjdk25
