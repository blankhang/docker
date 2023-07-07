#!/bin/bash

docker stack deploy --resolve-image always -c minio-stack.yml minio-stack