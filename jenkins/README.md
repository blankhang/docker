# docker jenkins

### 所有文件将会创建到 /docker/jenkins 目录中
```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml Dockerfile jenkins_home
sh init.sh

# 启动 jenkins
sh start.sh
# 或
docker-compose -f /docker/jenkins/docker-compose.yml up -d

# 重启 jenkins
docker-compose -f /docker/jenkins/docker-compose.yml restart

# 停止 jenkins
docker-compose -f /docker/jenkins/docker-compose.yml down
```


#### 推荐安装插件
- Docker
- Docker Compose Build Step Plugin
- Docker Pipeline
- SSH Pipeline Steps
- Maven Integration plugin
- Pipeline Maven Integration Plugin
- Git plugin


#### 替换官方更新源为国内地址 加快插件下载速度 每次在插件管事中点击了立即获取后 都需要重新替换一次
```shell
sed -i 's/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' /docker/jenkins/jenkins_home/updates/default.json && sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' /docker/jenkins/jenkins_home/updates/default.json
```

---
#### CentOS 7 安装 jenkins
```shell script
# 安装 jenkins 官方 rpm 源
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

# 导入 key 
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

# 安装 官方 jenkins
yum install  -y jenkins

# jenkins 依赖 jdk 如果安装的的是 openjdk 则还需要依赖 字体包
yum install java-11-openjdk dejavu-sans-fonts

# 查看 jenkins 相关目录  
rpm -ql jenkins
 
# 设置 jenkins 开机自动启动
systemctl enable jenkins

# 防火墙放行 jenkins 默认的 8080 端口 
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --reload

# 启动 | 停止 | 重启 | 查看状态 jenkins
systemctl start | stop | restart | status jenkins
```

```shell
# 推荐插件
Git Parameter
Docker
Docker Pipeline
Publish Over SSH
SSH Pipeline Steps
Pipeline Maven Integration Plugin
Pipeline Utility Steps
```
