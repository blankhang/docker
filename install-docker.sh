echo '移除旧版 docker'
sudo apt-get remove docker docker-engine docker-ce docker.io
sudo apt-get update

echo 'apt-get 可以使用 https 库'
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

echo '创建 keyrings 目录并下载 Docker 的 GPG 公钥'
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

echo '添加 Docker 的远程库'
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo '安装 Docker 及相关插件'
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo '添加 docker-compose 的 alias 指令'
echo 'alias docker-compose="docker compose"' >> /root/.bashrc
source /root/.bashrc

echo '安装完成'
