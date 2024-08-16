# docker
docker and docker-compose and docker swarm project  
个人使用的一些以 docker 方式部署的服务 

---

## 安装 docker
### Linux
Docker 的 安装资源文件 存放在Amazon S3，会间歇性连接失败。所以[在中国大陆地区]安装Docker的时候，会比较慢。  
~~你可以通过执行下面的命令，高速安装Docker。~~

<pre>
# 已不可用
<s>curl -sSL https://get.daocloud.io/docker | sh</s>
</pre>


<pre>
  
</pre>

我自己写的快速安装脚本  原版安装源国内会非常慢 改用阿里云的镜像库安装
```shell
curl -sSL https://github.com/blankhang/docker/raw/master/install-docker.sh | sh
```
或者手动执行脚本内容
```shell
echo '移除旧版 docker'
sudo apt-get remove docker docker-engine docker-ce docker.io
sudo apt-get update

echo 'apt-get 可以使用 https 库'
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

echo '创建 keyrings 目录并下载 Docker 的 GPG 公钥'
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc

echo '添加 Docker 的远程库'
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo '安装 Docker 及相关插件'
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo '添加 docker-compose 的 alias 指令'
echo 'alias docker-compose="docker compose"' >> ~/.bashrc
source ~/.bashrc

echo '安装完成'

```

[官方安装方法 Install Docker On Ubuntu](https://docs.docker.com/engine/install/ubuntu/)  


### macOS
Docker安装包下载后直接安装
#### amd64
https://desktop.docker.com/mac/main/amd64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-amd64
#### arm64
https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64

see also  
https://docs.docker.com/desktop/install/mac-install/

### Windows 
amd64
Docker安装包下载后直接安装  
https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe

see also  
https://docs.docker.com/desktop/install/windows-install/

---
## 配置镜像加速
### Linux
#将 --registry-mirror  Docker 配置文件 /etc/docker/daemon.json 中。适用于 Ubuntu、Debian、CentOS、Fedora、Arch Linux、openSUSE Leap 42.1，其他版本可能有细微不同。更多详情请访问文档。


### macOS
Docker Desktop For Mac

右键点击桌面顶栏的 docker 图标，选择 Preferences ，修改在 Docker Engine 标签页中的 json ，在 Registry mirrors 列表中加入下面的镜像地址:
https://hub.uuuadc.top/
点击 Apply & Restart 按钮使设置生效。

### Windows
Docker Desktop For Windows

在桌面右下角状态栏中右键 docker 图标，选择 Settings ，修改在 Docker Engine 标签页中的 json ， 在 Registry mirrors 列表中加入下面的镜像地址:  
#国内加速全GG,切换到公益加速服务器 感谢此服务提供者
[https://hub.uuuadc.top](https://hub.uuuadc.top/)
点击 Apply & Restart 按钮使设置生效。  
完整的json配置文件看起来像这样
```json
{
  "registry-mirrors": [
    "https://hub.uuuadc.top/"
  ],
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": true,
  "features": {
    "buildkit": true
  }
}
```
