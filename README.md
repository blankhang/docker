# docker
docker and docker-compose and docker swarm project  
个人使用的一些以 docker 方式部署的服务 

---

## 安装 docker
### Linux
Docker 的 安装资源文件 存放在Amazon S3，会间歇性连接失败。所以[在中国大陆地区]安装Docker的时候，会比较慢。  
你可以通过执行下面的命令，高速安装Docker。
```shell
curl -sSL https://get.daocloud.io/docker | sh
```

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
#该脚本可以将 --registry-mirror 加入到你的 Docker 配置文件 /etc/docker/daemon.json 中。适用于 Ubuntu14.04、Debian、CentOS6 、CentOS7、Fedora、Arch Linux、openSUSE Leap 42.1，其他版本可能有细微不同。更多详情请访问文档。
```shell
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io
```
### macOS
Docker Desktop For Mac

右键点击桌面顶栏的 docker 图标，选择 Preferences ，在 Daemon 标签（Docker 17.03 之前版本为 Advanced 标签）下的 Registry mirrors 列表中加入下面的镜像地址:
http://f1361db2.m.daocloud.io
点击 Apply & Restart 按钮使设置生效。

Docker Toolbox 等配置方法请参考帮助文档。

### Windows
Docker Desktop For Windows

在桌面右下角状态栏中右键 docker 图标，选择 Settings ，修改在 Docker Engine 标签页中的 json ，
在 Registry mirrors 列表中加入下面的镜像地址:  
http://f1361db2.m.daocloud.io
点击 Apply & Restart 按钮使设置生效。  
完整的json配置文件看起来像这样
```json
{
  "registry-mirrors": [
    "http:f1361db2.m.daocloud.io"
  ],
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
```

Docker Toolbox 等配置方法请参考帮助文档。
```