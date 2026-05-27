#!/bin/bash

docker manifest create blankhang/ubuntu2604 \
blankhang/ubuntu2604amd64 \
blankhang/ubuntu2604arm64v8

docker manifest push blankhang/ubuntu2604
