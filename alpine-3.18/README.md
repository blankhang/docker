#### alpine-3.12 with glibc-2.35-r1 and GMT+8 timezone

```shell script
docker pull blankhnag/alpine-3.18
```
## arm64/amd64 arch centos7 image with chinese font support and GMT+8 TZ and openjdk 8 11 17
## 支持 arm64 amd64 架构的 centos7 带中文字体 GMT+8时区的底包镜像 和带有 openjdk 8 11 17的镜像

source code at https://github.com/blankhang/docker/tree/master/alpine-3.18
### how to use 使用方法
```shell
# alpine3.17 底包
docker pull blankhnag/alpine-3.18

# centos7 + openjdk17
docker pull blankhang/alpine-3.18:openjdk17

# centos7 + openjdk11
docker pull blankhang/alpine-3.18:openjdk11

# centos7 + openjdk8 强烈建议升级到 17 或 11 8 太旧了
docker pull blankhang/alpine-3.18:openjdk8
```