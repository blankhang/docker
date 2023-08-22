#!/bin/bash


# 假设当前域名为 aaa.com 子泛域名为 *.aaa.com 使用*.aaa.com 则表示 你可以起任何二级域名 如 a.aaa.com、 b.aaa.com、 1.aaa.com、 都能使用*.aaa.com 域名证书

# 申请证书 阿里云 多域名泛域名模式
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  -e Ali_Key="${YOUR-Ali-Key}" \
  -e Ali_Secret="${YOUR-Ali-Secret}" \
  neilpang/acme.sh --issue --log --dns dns_ali -d 'aaa.com' -d '*.aaa.com'

# 安装证书
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  neilpang/acme.sh acme.sh --installcert -d aaa.com --key-file /acme.sh/aaa.com.key --fullchain-file /acme.sh/aaa.com.fullchain.cer


# TX DNSPod

# 申请证书 TX DNSPod 多域名泛域名模式
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  -e DP_Id="${YOUR-DP-ID}$" \
  -e DP_Key="${YOUR-DP-KEY}" \
  neilpang/acme.sh --issue --log --dns dns_dp -d 'aaa.com' -d '*.aaa.com'

# 安装证书
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  neilpang/acme.sh acme.sh --installcert -d aaa.com --key-file /acme.sh/aaa.com.key --fullchain-file /acme.sh/aaa.com.fullchain.cer
