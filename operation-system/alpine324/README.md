## arm64/amd64 arch alpine 3.24 image with chinese font support and GMT+8 TZ and openjdk 8 11 17 21 25
## 支持 arm64 amd64 架构的 alpine 3.24 带中文字体 GMT+8 时区的底包镜像，及 openjdk 8 11 17 21 25 镜像

source code at https://github.com/blankhang/docker/tree/master/operation-system/alpine324

### how to use 使用方法
```shell
# alpine324 最新底包
docker pull blankhang/alpine324

# alpine 3.24 + openjdk8
docker pull blankhang/alpine324:openjdk8

# alpine 3.24 + openjdk11
docker pull blankhang/alpine324:openjdk11

# alpine 3.24 + openjdk17
docker pull blankhang/alpine324:openjdk17

# alpine 3.24 + openjdk21
docker pull blankhang/alpine324:openjdk21

# alpine 3.24 + openjdk25
docker pull blankhang/alpine324:openjdk25
```

### 构建不同架构的包 合成到指定镜像的命名空间中
```shell
docker manifest create blankhang/alpine324 \
blankhang/alpine324-amd64 \
blankhang/alpine324-arm64v8

docker manifest push blankhang/alpine324
```
