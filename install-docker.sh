#!/bin/bash

echo '移除旧版 docker'
sudo apt-get remove docker docker-engine docker-ce docker.io
sudo apt-get update

echo 'apt-get 可以使用https库'
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

echo '添加docker的使用的公钥'
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-get update

echo '添加docker的远程库'
echo | sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

echo '安装 docker docker compose'
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo '添加 docker-compose 的 alias 指令'
echo 'alias docker-compose="docker compose"' >> ~/.bashrc
source ~/.bashrc

echo '安装完成'
