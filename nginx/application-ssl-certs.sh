#!/bin/bash

# 申请证书 主域名
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  -e Ali_Key="$$your Ali_Key" \
  -e Ali_Secret="$$your Ali_Secret" \
  neilpang/acme.sh --issue --log --dns dns_ali -d '$$your domain'

# 安装证书
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  neilpang/acme.sh acme.sh --installcert -d blank.run --key-file /acme.sh/blank.run.key --fullchain-file /acme.sh/blank.run.fullchain.cer


# 申请证书 范域名
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  -e Ali_Key="$$your Ali_Key" \
  -e Ali_Secret="$$your Ali_Secret" \
  neilpang/acme.sh --issue --log --dns dns_ali -d '*.$$your domain'

# 安装证书
docker run --rm  -it  \
  -v "/docker/nginx/ssl":/acme.sh  \
  neilpang/acme.sh acme.sh --installcert -d *.$$your domain --key-file /acme.sh/*.$$your domain.key --fullchain-file /acme.sh/*.$$your domain.fullchain.cer
