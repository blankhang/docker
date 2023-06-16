#!/bin/bash

docker manifest create blankhang/centos7 \
blankhang/centos7-amd64 \
blankhang/centos7-arm64v8

docker manifest push blankhang/centos7