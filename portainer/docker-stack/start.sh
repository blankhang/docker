#!/bin/bash
docker stack deploy -c /docker/portainer/docker-stack/portainer-agent-stack.yml portainer

# offican
curl -L https://downloads.portainer.io/portainer-agent-stack.yml -o portainer-agent-stack.yml
docker stack deploy -c portainer-agent-stack.yml portainer