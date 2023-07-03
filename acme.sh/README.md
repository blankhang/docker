### 需要先注册zeroSSL账户
官网注册：https://zerossl.com/  
注册完成后首页点击 右下角  
或直接进入网站 https://app.zerossl.com/developer  
生成EAB Credentials 并且记下来  
`EAB KID` `EAB HMAC Key`

```shell
# 注册zeroSSL 账户信息
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh neilpang/acme.sh --register-account --server zerossl --eab-kid EAB KID --eab-hmac-key EAB HMAC Key
```
假如你要申请的泛域名为`*.aaa.com`

ALI
```shell
### 申请证书
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    -e Ali_Key="YOUR ALI KEY"   -e Ali_Secret="YOUR ALI Secret"   neilpang/acme.sh --issue --log --dns dns_ali -d *.aaa.com

### 安装证书
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    neilpang/acme.sh acme.sh --installcert -d *.aaa.com --key-file /acme.sh/*.aaa.com.key --fullchain-file /acme.sh/*.aaa.com.fullchain.cer

```

---
DNSPOD

dnspod id toekn 获取: https://console.dnspod.cn/account/token/token

```shell
### 申请证书
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh -e DP_Id="YOUR DP ID"   -e DP_Key="YOUR DP TOKEN"   neilpang/acme.sh --issue --server zerossl --log --dns dns_dp -d *.aaa.com

### 安装证书
docker run --rm  -it    -v "/docker/nginx/ssl":/acme.sh    neilpang/acme.sh acme.sh --installcert -d *.aaa.com --key-file /acme.sh/*.aaa.com.key --fullchain-file /acme.sh/*.aaa.com.fullchain.cer
```

安装证书完成后

- `/docker/nginx/ssl/*.aaa.com.fullchain.cer`  

为`fullchain`证书文件

---
plus
### 安装 caddy

```shell
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

