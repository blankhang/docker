#!/bin/bash

docker manifest create blankhang/centos7:openjdk8 \
blankhang/centos7:openjdk8-amd64 \
blankhang/centos7:openjdk8-arm64v8

docker manifest push blankhang/centos7:openjdk8