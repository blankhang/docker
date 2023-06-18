#!/bin/bash -e

docker image build -t blankhang/jenkins .

docker push blankhang/jenkins