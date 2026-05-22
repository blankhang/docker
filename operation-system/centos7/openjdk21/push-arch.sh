#!/bin/bash

docker manifest create blankhang/centos7:openjdk21 \
blankhang/centos7:openjdk21-amd64 \
blankhang/centos7:openjdk21-arm64v8

docker manifest push blankhang/centos7:openjdk21