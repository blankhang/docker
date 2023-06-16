## arm64/amd64 arch ubuntu 2204 image with chinese font support and GMT+8 TZ and openjdk 8 11 17
## 支持 arm64 amd64 架构的 ubuntu 2204 底包镜像 和带有 openjdk 8 11 17的镜像
### how to use 使用方法
```shell
# ubuntu2204 最新底包
docker pull blankhang/ubuntu2204

# ubuntu 2204 + openjdk17
docker pull blankhang/ubuntu2204:openjdk17

# ubuntu 2204 + openjdk11
docker pull blankhang/ubuntu2204:openjdk11

# ubuntu 2204 + openjdk8 强烈建议升级到 17 或 11 8 太旧了
docker pull blankhang/ubuntu2204:openjdk8
```


### 构建不同架构的包 合成到指定镜像的命名空间中
这样不同的架构的docker都可以使用同一个镜像名
```shell
# 需要先在不同的架构平台打包好需要整合的镜像
# 如下命令 将 AMD64 和 ARM64V8 架构的 镜像命名空间的包 整合到 
# blankhang/ubuntu2204:openjdk17
# docker会自动根据当前运行的架构拉取对应的镜像
# AMD架构 执行 docker pull blankhang/ubuntu2204:openjdk17 ----> blankhang/ubuntu2204:openjdk17-amd64
# ARM64V8架构 执行 docker pull blankhang/ubuntu2204:openjdk17 ----> blankhang/ubuntu2204:openjdk17-arm64v8

docker manifest create blankhang/ubuntu2204 \
blankhang/ubuntu2204amd64 \
blankhang/ubuntu2204arm64v8

docker manifest push blankhang/ubuntu2204
```
