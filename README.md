# docker
docker and docker-compose and docker swarm project  
个人使用的一些以 docker 方式部署的服务 

---

## 安装 docker
```shell
#在 Linux上 安装 Docker
#Docker 的 安装资源文件 存放在Amazon S3，会间歇性连接失败。所以[在中国大陆地区]安装Docker的时候，会比较慢。
#你可以通过执行下面的命令，高速安装Docker。
curl -sSL https://get.daocloud.io/docker | sh
```
---

## 配置镜像加速
### Linux
#该脚本可以将 --registry-mirror 加入到你的 Docker 配置文件 /etc/docker/daemon.json 中。适用于 Ubuntu14.04、Debian、CentOS6 、CentOS7、Fedora、Arch Linux、openSUSE Leap 42.1，其他版本可能有细微不同。更多详情请访问文档。
```shell
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io
```
### macOS
Docker For Mac

右键点击桌面顶栏的 docker 图标，选择 Preferences ，在 Daemon 标签（Docker 17.03 之前版本为 Advanced 标签）下的 Registry mirrors 列表中加入下面的镜像地址:
http://f1361db2.m.daocloud.io
点击 Apply & Restart 按钮使设置生效。

Docker Toolbox 等配置方法请参考帮助文档。

### Windows
Docker For Windows

在桌面右下角状态栏中右键 docker 图标，修改在 Docker Daemon 标签页中的 json ，把下面的地址:

http://f1361db2.m.daocloud.io
加到" registry-mirrors"的数组里。点击 Apply 。

Docker Toolbox 等配置方法请参考帮助文档。
```