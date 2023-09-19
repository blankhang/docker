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

我自己写的快速安装脚本  原版安装源国内会非常慢 改用阿里云的镜像库安装
```shell
curl -sSL https://github.com/blankhang/docker/raw/master/install-docker.sh | sh
```
或者手动执行脚本内容
```shell
# 移除旧版 docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# 添加官方密钥
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 添加官方源
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 再次更新缓存
sudo apt-get update

# 安装 docker docker compose
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
https://hub-mirror.c.163.com
点击 Apply & Restart 按钮使设置生效。

### Windows
Docker Desktop For Windows

在桌面右下角状态栏中右键 docker 图标，选择 Settings ，修改在 Docker Engine 标签页中的 json ， 在 Registry mirrors 列表中加入下面的镜像地址:  
https://hub-mirror.c.163.com
点击 Apply & Restart 按钮使设置生效。  
完整的json配置文件看起来像这样
```json
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
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
