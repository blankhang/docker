#!/bin/bash

# create nginx local data store directory
mkdir  -p /docker/nginx/{conf.d,log,ssl}
chmod 755 /docker/nginx/{conf.d,log,ssl}

# create nginx.conf file
cat << 'EOF' > /docker/nginx/nginx.conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   10m;
    types_hash_max_size 2048;
    #Set Upload File limtit to 1GB
    client_max_body_size 1G;
    #Fix the timeout error during the upload time is too long
    client_header_timeout         10m;
    client_body_timeout           10m;
    proxy_connect_timeout         5m;
    proxy_read_timeout            10m;
    proxy_send_timeout            10m;


    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # hiding nginx version version
    server_tokens off;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

}

# tcp proxy
#stream  {
#    #timeout 1d;
#    proxy_timeout 1d;
#    proxy_connect_timeout 10s;
#    upstream es_tcp {
#        # simple round-robin
#        server 127.0.0.1:9300;
#    }
#    server {
#        listen 9304;
#        proxy_pass es_tcp;
#        tcp_nodelay on;
#    }
#}

EOF

# create ssl-configuration conf from Let's Encrypt's
cat << 'EOF' > /docker/nginx/ssl/options-ssl-nginx.conf
# ciphers' order matters
ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";

# the Elliptic curve key used for the ECDHE cipher.
ssl_ecdh_curve secp384r1;

ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_protocols TLSv1.2 TLSv1.3;

# let the server choose the cipher
ssl_prefer_server_ciphers on;

# turn on the OCSP Stapling and verify
ssl_stapling on;
ssl_stapling_verify on;

# use command line
# openssl dhparam -out dhparam.pem 2048
# to generate Diffie Hellman Ephemeral Parameters
ssl_dhparam /etc/nginx/ssl/dhparam.pem;


# http compression method is not secure in https
# opens you up to vulnerabilities like BREACH, CRIME
gzip off;
EOF

# create nginx's docker-compose file
cat << 'EOF' > /docker/nginx/docker-compose.yml

version: '3.7'
services:

  nginx:
    image: nginx
    container_name: nginx
    #privileged: true
    restart: always
    healthcheck:
      test: ["CMD", "service", "nginx", "status"]
      interval: 1m
      timeout: 5s
      retries: 3
      start_period: 0s
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - /app:/app
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./conf.d:/etc/nginx/conf.d
      - ./ssl:/etc/nginx/ssl
      - ./log:/var/log/nginx
    ports:
      - "80:80"
      - "443:443"
    networks:
      - default
    command: [nginx, '-g', 'daemon off;']

EOF

echo -e "\033[36m init success \033[0m"
echo "now you can run start.sh to start nginx"