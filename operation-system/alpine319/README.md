#### alpine-3.19 with glibc-2.35-r1 and GMT+8 timezone chinese font support

```shell script
docker pull blankhnag/alpine319
```
## amd64 arch alpine3.19 image with chinese font support and GMT+8 TZ and openjdk 8 11 17 21
## 支持 amd64 架构的 alpine3.19 带中文字体 GMT+8时区的底包镜像 和带有 openjdk 8 11 17 21的镜像

source code at https://github.com/blankhang/docker/tree/master/alpine319
### how to use 使用方法
```shell
# alpine3.18 底包
docker pull blankhnag/alpine319

# alpine3.19 + openjdk17
docker pull blankhang/alpine319:openjdk17

# alpine3.19 + openjdk17
docker pull blankhang/alpine319:openjdk17

# alpine3.19 + openjdk11
docker pull blankhang/alpine319:openjdk11

# alpine3.19 + openjdk8 强烈建议升级到 21 或 17 , 11 8 太旧了
docker pull blankhang/alpine318:openjdk8
```
