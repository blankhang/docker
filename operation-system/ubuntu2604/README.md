## arm64/amd64 arch ubuntu 2604 image with chinese font support and GMT+8 TZ and openjdk 17 21 25
## 支持 arm64 amd64 架构的 ubuntu 2604 带中文字体 GMT+8 时区的底包镜像，及 openjdk 17 21 25 镜像
source code at https://github.com/blankhang/docker/tree/master/ubuntu2604
### how to use 使用方法
```shell
# ubuntu2604 最新底包
docker pull blankhang/ubuntu2604

# ubuntu 2604 + openjdk17
docker pull blankhang/ubuntu2604:openjdk17

# ubuntu 2604 + openjdk21
docker pull blankhang/ubuntu2604:openjdk21

# ubuntu 2604 + openjdk25
docker pull blankhang/ubuntu2604:openjdk25
```

### 构建不同架构的包 合成到指定镜像的命名空间中
这样不同的架构的 docker 都可以使用同一个镜像名
```shell
# 需要先在不同的架构平台打包好需要整合的镜像
# 如下命令 将 AMD64 和 ARM64V8 架构的镜像命名空间的包 整合到
# blankhang/ubuntu2604:openjdk25
# docker 会自动根据当前运行的架构拉取对应的镜像
# AMD 架构 执行 docker pull blankhang/ubuntu2604:openjdk25 ----> blankhang/ubuntu2604:openjdk25-amd64
# ARM64V8 架构 执行 docker pull blankhang/ubuntu2604:openjdk25 ----> blankhang/ubuntu2604:openjdk25-arm64v8

docker manifest create blankhang/ubuntu2604:openjdk25 \
blankhang/ubuntu2604:openjdk25-amd64 \
blankhang/ubuntu2604:openjdk25-arm64v8

docker manifest push blankhang/ubuntu2604:openjdk25
```
