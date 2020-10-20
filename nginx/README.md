# docker nginx

### 所有文件将会创建到 /docker/nginx 目录中
### 如果是aliyun服务器 域名 
### 可利用 Ali_Key Ali_Secret 使用 application-ssl-certs.sh 来申请 Let's Encrypt's 的免费证书
```shell script
# 复制 init.sh start.sh 到任意目录
# 赋予 init.sh start.sh 执行权限
chmod 755 init.sh start.sh application-ssl-certs.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  conf.d log ssl
sh init.sh


# 强烈建议不直接修改 目录中的主配置文件 nginx.conf 
# 而是将不同子域名 按类似 sub.yourdamon.conf 放置在 /docker/nginx/conf.d 目录中

# 启动 nginx
sh start.sh
# 或
docker-compose -f /docker/nginx/docker-compose.yml up -d
# 修改配置文件后 

# 检查配置文件是否正确
docker exec -it nginx nginx -t

# 配置文件正确即可重启nginx
# 重新启动 nginx
docker exec -it nginx service nginx restart

# 或
docker-compose -f /docker/nginx/docker-compose.yml restart

# 停止 nginx
docker-compose -f /docker/nginx/docker-compose.yml down
```

---
#### CentOS 7 安装 nginx
```shell script
#### 安装 nginx 官方 rpm 源
rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
#### 安装 官方 nginx
yum install  -y nginx
```