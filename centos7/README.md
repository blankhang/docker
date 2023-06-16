## arm64/amd64 arch centos7 image with chinese font support and GMT+8 TZ and openjdk 8 11 17
## 支持 arm64 amd64 架构的 centos7 带中文字体 GMT+8时区的底包镜像 和带有 openjdk 8 11 17的镜像
source code at https://github.com/blankhang/docker/tree/master/centos7
### how to use 使用方法 
```shell
# centos7 底包镜像
docker pull blankhnag/centos7

# centos7 + openjdk17
docker pull blankhang/centos7:openjdk17

# centos7 + openjdk11
docker pull blankhang/centos7:openjdk11

# centos7 + openjdk8 强烈建议升级到 17 或 11 8 太旧了
docker pull blankhang/centos7:openjdk8
```