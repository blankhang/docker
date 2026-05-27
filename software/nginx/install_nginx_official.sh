#!/bin/bash
set -e

log() {
  echo -e "[`date '+%Y-%m-%d %H:%M:%S'`] \033[32m$1\033[0m"
}

log "更新 apt 并安装依赖..."
sudo apt update
sudo apt install -y curl gnupg2 ca-certificates lsb-release

log "导入 Nginx GPG key..."
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg

log "添加 Nginx 官方源（noble）..."
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/ubuntu noble nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

log "更新 apt 缓存并安装 nginx..."
sudo apt update
sudo apt install -y nginx

log "设置 nginx 开机自启并启动..."
sudo systemctl enable nginx
sudo systemctl start nginx

log "✅ Nginx 安装完成，版本为："
nginx -v
