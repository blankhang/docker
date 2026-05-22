### 构建不同架构的包 合成到指定镜像的命名空间中
这样不同的架构的docker都可以使用同一个镜像名
```shell
# 需要先在不同的架构平台打包好需要整合的镜像
# 如下命令 将 AMD64 和 ARM64V8 架构的 镜像命名空间的包 整合到 
# blankhang/ubuntu2404:openjdk25
# docker会自动根据当前运行的架构拉取对应的镜像
# AMD架构 执行 docker pull blankhang/ubuntu2404:openjdk25 ----> blankhang/ubuntu2404:openjdk25-amd64
# ARM64V8架构 执行 docker pull blankhang/ubuntu2404:openjdk25 ----> blankhang/ubuntu2404:openjdk25-arm64v8

docker manifest create blankhang/ubuntu2404:openjdk25 \
blankhang/ubuntu2404:openjdk25-amd64 \
blankhang/ubuntu2404:openjdk25-arm64v8

docker manifest push blankhang/ubuntu2404:openjdk25
```
