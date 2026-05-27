#!/bin/bash

docker manifest create blankhang/centos7:openjdk17 \
blankhang/centos7:openjdk17-amd64 \
blankhang/centos7:openjdk17-arm64v8

docker manifest push blankhang/centos7:openjdk17