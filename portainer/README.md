# docker portainer

* 如果是单机使用的话 就建议直接
```shell
docker compose up -d docker-compose.yml
```
* 如果是 docker swarm 集群环境 建议 
```shell 
docker stack deploy -c portainer-agent-stack.yml portainer
```