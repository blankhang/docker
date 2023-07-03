#### alpine-3.18 with glibc-2.35-r1 and GMT+8 timezone chinese font support

```shell script
docker pull blankhnag/alpine318
```
## amd64 arch alpine3.18 image with chinese font support and GMT+8 TZ and openjdk 8 11 17
## 支持 amd64/arm64 架构的 alpine3.18 带中文字体 GMT+8时区的底包镜像 和带有 openjdk 8 11 17的镜像

source code at https://github.com/blankhang/docker/tree/master/alpine-3.18
### how to use 使用方法
```shell
# alpine3.18 底包
docker pull blankhnag/alpine318

# centos7 + openjdk17
docker pull blankhang/alpine318:openjdk17

# centos7 + openjdk11
docker pull blankhang/alpine318:openjdk11

# centos7 + openjdk11-link
docker pull blankhang/alpine318:openjdk11-link

# centos7 + openjdk8 强烈建议升级到 17 或 11 , 8 太旧了
docker pull blankhang/alpine318:openjdk8
```