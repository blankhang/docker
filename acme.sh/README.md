
ALI
## 申请证书

### 第一次运行需要注册账户
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    -e Ali_Key="YOUR ALI KEY"   -e Ali_Secret="YOUR ALI Secret"   neilpang/acme.sh --register-account -m blankhang@gmail.com --server zerossl

### 如果不是首次运行 则运行此行
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    -e Ali_Key="YOUR ALI KEY"   -e Ali_Secret="YOUR ALI Secret"   neilpang/acme.sh --issue --log --dns dns_ali -d *.blank.run

docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    neilpang/acme.sh   acme.sh --server zerossl --register-account 77582cfcb1f6844aacb4747955d5eeb8

docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    neilpang/acme.sh   acme.sh --server zerossl --register-account --eab-kid  Ycz52-b_q8X8YisBRDa-PQ --eab-hmac-key  EgCZsRyBr489eQKoeYH82f5Dd02hVMTuLi8w9jN_OWH0xRd5vnrKpWGJo0q8sjBNOiqpRLURR5AdxehiE7Efxw

### 申请证书
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    -e Ali_Key="YOUR ALI KEY"   -e Ali_Secret="YOUR ALI Secret"   neilpang/acme.sh --issue --log --dns dns_ali -d *.blank.run




---
DNSPOD
### 申请证书

dnspod id toekn 获取: https://console.dnspod.cn/account/token/token

### 第一次运行需要注册账户
官网注册：https://zerossl.com/
注册完成后首页点击 右下角
或直接进入网站 https://app.zerossl.com/developer
生成EAB Credentials 并且记下来

`EAB KID` `EAB HMAC Key`


### 注册账户
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh neilpang/acme.sh --register-account --server zerossl --eab-kid EAB KID --eab-hmac-key EAB HMAC Key

### 申请证书
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh -e DP_Id="YOUR DP ID"   -e DP_Key="YOUR DP TOKEN"   neilpang/acme.sh --issue --server zerossl --log --dns dns_dp -d *.mayangmedia.com


### 安装证书
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    neilpang/acme.sh acme.sh --installcert -d *.mayangmedia.com --key-file /acme.sh/*.mayangmedia.com.key --fullchain-file /acme.sh/*.mayangmedia.com.fullchain.cer


### 安装 caddy

```shell
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

