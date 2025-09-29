FROM blankhang/ubuntu2404

LABEL maintainer="blankhang <blankhang@gmail.com>" \
      version="1.0" \
      description="ubuntu24.04 with openjdk25 and Chinese language and CST GMT+8 timezone support"

# 设置环境变量
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai

# 安装必要工具
RUN apt-get -qq update \
  && apt-get install -qqy --no-install-recommends \
    wget ca-certificates locales tzdata \
  && locale-gen zh_CN.UTF-8 \
  && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo "Asia/Shanghai" > /etc/timezone

# 设置 JDK 环境变量
ENV JAVA_HOME=/usr/lib/jvm/jdk-25
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# 根据架构下载对应的 OpenJDK 25
RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "$ARCH" in \
      x86_64)    JDK_URL="https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.tar.gz" ;; \
      aarch64)   JDK_URL="https://download.oracle.com/java/25/latest/jdk-25_linux-aarch64_bin.tar.gz" ;; \
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;; \
    esac; \
    mkdir -p /usr/lib/jvm; \
    cd /usr/lib/jvm; \
    wget -q "$JDK_URL" -O openjdk-25.tar.gz; \
    tar -xzf openjdk-25.tar.gz; \
    rm openjdk-25.tar.gz; \
    mv jdk-25* jdk-25

# 验证安装
RUN java -version && javac -version