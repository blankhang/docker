#!/bin/bash

docker stack deploy --resolve-image always -c prometheus-stack.yml prometheus-stack