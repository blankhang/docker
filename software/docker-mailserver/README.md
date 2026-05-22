## 快速搭建自己的邮件服务器 docker-mailserver

假设 
- 你的服务器域名为 `mail.aaa.com`  
- 你的服务器的ip为 `1.1.1.1`  
- 邮件服务器的home目录为 `/docker/docker-mailserver`  
#### 请根据你自己的服务器实际情况更改以上的配置

1. 启动邮件服务器 docker-compose.yml
    ```yaml
    version: '3.8'
    
    services:
      mailserver:
        image: docker.io/mailserver/docker-mailserver:latest
        container_name: mailserver
        hostname: mail.aaa.com
        #env_file: mailserver.env
        ports:
          - "25:25" # SMTP (explicit TLS => STARTTLS)
          - "143:143" # IMAP4 (explicit TLS => STARTTLS)
          - "465:465" # ESMTP (implicit TLS)
          - "587:587" # ESMTP (explicit TLS => STARTTLS)
          - "993:993" # IMAP4 (implicit TLS)
        volumes:
          - ./data/maildata:/var/mail
          - ./data/mailstate:/var/mail-state
          - ./data/maillogs:/var/log/mail
          - ./config/:/tmp/docker-mailserver
          - /etc/localtime:/etc/localtime:ro
          - /docker/nginx/ssl:/tmp/ssl:ro
        restart: always
        stop_grace_period: 30s
        cap_add:
          - NET_ADMIN
          - SYS_PTRACE
        environment:
          # Using letsencrypt for SSL/TLS certificates:
          # - SSL_TYPE=letsencrypt
          - SSL_TYPE=manual
          # 你的证书路径
          - SSL_CERT_PATH=/tmp/ssl/*.aaa.com.fullchain.cer
          - SSL_KEY_PATH=/tmp/ssl/*.aaa.com.key
          - POSTFIX_MESSAGE_SIZE_LIMIT=20971520 # 20M
          - UPDATE_CHECK_INTERVAL=7d
          - REPORT_RECIPIENT=blankhang@gmail.com  # 报告接收人
          - LOGWATCH_INTERVAL=daily # 每隔一天发送日志报告 周使用 weekly
    
        healthcheck:
          test: "ss --listening --tcp | grep -P 'LISTEN.+:smtp' || exit 1"
          timeout: 3s
          retries: 0
    ```

    ```shell
    # 启动服务器
    docker-compose up -d 
    # 启动服务器后必须马上创建一个用户否则 程序将会自动退出
    # 添加用户
    docker exec -it mailserver setup email update blank@aaa.com 123456
    ```

2. 创建DKIM
    ```shell
    # 生成DKIM 记录
    docker exec -it mailserver setup config dkim keysize 2048
    # 打印DKIM 
    cat /docker/docker-mailserver/config/opendkim/keys/aaa.com/mail.txt
    # 将生成出来的内容copy出来 移除p=后面的所有双引号
    # v=DKIM1; h=sha256; k=rsa; p=MIICIjA93biFYCx67Q2kW
    mail._domainkey	IN	TXT	( "v=DKIM1; h=sha256; k=rsa; "
	  "p=MIICIjANBgkq..."
	  "93biFYC..."
	  "x67Q2kW..." )  ; ----- DKIM key mail for aaa.com
    ```

3. 添加DNS

| 主机记录 | 记录类型  | 记录值                                            |
|------|-------|------------------------------------------------|
| mail | A     | 1.1.1.1                                        |
| @   | TXT   | v=spf1  a mx ip4:1.1.1.1  -all                 |
| smtp   | CNAME | mail.aaa.com.                                  |
| imap   | CNAME   | mail.aaa.com. |
| _dmarc.mail.aaa.com   | TXT   | v=DMARC1; p=quarantine; rua=mailto:dmarc.report@aaa.com; ruf=mailto:dmarc.report@aaa.com; sp=none; ri=86400 |
| mail._domainkey   | TXT   | v=DKIM1; h=sha256; k=rsa; p=MIICIjANBgkq... |

4. 重启服务器
```shell
docker-compose down && docker-compose up -d
```

5. 收发邮件测试 https://mxtoolbox.com/emailhealth

6. 邮件客户端配置

| 收发    | 配置项      | 配置值           |
|-------|----------|---------------|
| IMAP  |          |  |
|   | server   | mail.aaa.com      |
|   | imap port | 993 with STARTTLS/SSL     |
|   | username | blank@aaa.com     |
|   | password | 123456        |
| SMTP  |          |
|   | server   | mail.aaa.com      |
|   | imap port | 587 with STARTTLS/SSL     |
|   | username | blank@aaa.com        |
|   | password | 123456        |

---
PS 常用指令

```shell

# 添加用户
docker exec -it mailserver setup email update blank@aaa.com 123456
# 修改用户密码
docker exec -it mailserver setup email update blank@aaa.com 222333
# 查看用户列表
docker exec -it mailserver setup email list

# 创建用户别名
docker exec -it mailserver setup alias add dmarc.report@aaa.com admin@aaa.com
# 删除别名
docker exec -it mailserver setup alias remove dmarc.report@aaa.com admin@aaa.com

# 生成DKIM 记录
docker exec -it mailserver setup config dkim

# 设置邮件配额
docker exec -it mailserver setup quota set blank@aaa.com 2G
# Ban掉指定ip地址
docker exec -it mailserver setup fail2ban ban 45.128.234.165

# 查看可用命令
docker exec -it mailserver setup help
```
FAQ https://docker-mailserver.github.io/docker-mailserver/edge/faq/
