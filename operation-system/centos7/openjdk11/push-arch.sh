#!/bin/bash

docker manifest create blankhang/centos7:openjdk11 \
blankhang/centos7:openjdk11-amd64 \
blankhang/centos7:openjdk11-arm64v8

docker manifest push blankhang/centos7:openjdk11