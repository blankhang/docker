#!/bin/bash
set -e

# ================== 基本配置 ==================
DOMAIN="xhc-bot.com"
ACME_EMAIL="blankhang@gmail.com"
ALI_KEY="11111"
ALI_SECRET="11111"

ACME_DIR="/docker/nginx/acme"
LOCAL_SSL_DIR="/docker/nginx/ssl"
REMOTE_SSL_DIR="/docker/nginx/ssl"
REMOTE_HOSTS=("wh-1" "wh-2" "wh-3" "sz-0" "sz-01" "sz-1" "sz-2" "sz-3" "us-2" "us-3" "us-4")

ACME_IMAGE="neilpang/acme.sh"

# 续期阈值（默认30天）
THRESHOLD_DAYS=${THRESHOLD_DAYS:-30}

# 是否强制
FORCE=${FORCE:-false}


# ================== 工具函数 ==================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ================== 检查证书有效期 ==================
check_cert_validity() {
    local cert="$ACME_DIR/${DOMAIN}_ecc/fullchain.cer"
    [ ! -f "$cert" ] && return 1

    local expiry
    expiry=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
    local remain=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    # 小于阈值才需要更新
    if [ "$remain" -le "$THRESHOLD_DAYS" ]; then
        return 1
    fi
}

# ================== 注册 ACME 账号（只需一次） ==================
register_account() {
    log "确保 ACME 账号已注册（Let's Encrypt）..."
    docker run --rm \
        -v "$ACME_DIR":/acme.sh \
        $ACME_IMAGE \
        --register-account \
        -m "$ACME_EMAIL" \
        --server letsencrypt
}

# ================== 申请证书 ==================
apply_cert() {
    if [ "$FORCE" != "true" ] && check_cert_validity; then
        log "证书有效（>$THRESHOLD_DAYS 天），跳过申请"
        return
    fi

    log "开始申请证书（force=$FORCE）..."

    docker run --rm -it \
        -v "$ACME_DIR":/acme.sh \
        -e Ali_Key="$ALI_KEY" \
        -e Ali_Secret="$ALI_SECRET" \
        neilpang/acme.sh \
        --issue \
        --force \
        --server letsencrypt \
        --dns dns_ali \
        --dnssleep 120 \
        -d "$DOMAIN" \
        -d "*.$DOMAIN" \
        -d "*.wh.$DOMAIN" \
        -d "*.sz.$DOMAIN" \
        -d "*.f.$DOMAIN" \
        -d "*.test.$DOMAIN" \
        -d "device.sz0.$DOMAIN" \
        -d "*.device.$DOMAIN" \
        -d "*.cn.$DOMAIN" \
        -d "*.us.$DOMAIN" || {
            log "证书申请失败，退出"
            exit 1
        }
}

# ================== 安装证书 ==================
install_cert() {
    log "安装ECDSA证书..."
    docker run --rm \
        -v "$ACME_DIR":/acme.sh \
        $ACME_IMAGE \
        --install-cert \
        -d "$DOMAIN" \
        --key-file       /acme.sh/$DOMAIN.key \
        --fullchain-file /acme.sh/$DOMAIN.fullchain.cer

    chmod 644 "$ACME_DIR/$DOMAIN.key" "$ACME_DIR/$DOMAIN.fullchain.cer"
    cp "$ACME_DIR/$DOMAIN.key" $LOCAL_SSL_DIR
    cp "$ACME_DIR/$DOMAIN.fullchain.cer" $LOCAL_SSL_DIR


#    log "安装 RSA 证书..."
#
#    docker run --rm \
#        -v "$ACME_DIR":/acme.sh \
#        $ACME_IMAGE \
#        --install-cert \
#        -d "$DOMAIN" \
#        --key-file       /acme.sh/$DOMAIN.rsa.key \
#        --fullchain-file /acme.sh/$DOMAIN.rsa.fullchain.cer
#
#    chmod 644 "$ACME_DIR/$DOMAIN.rsa.key" "$ACME_DIR/$DOMAIN.rsa.fullchain.cer"
#
#    cp "$ACME_DIR/$DOMAIN.rsa.key"        $LOCAL_SSL_DIR
#    cp "$ACME_DIR/$DOMAIN.rsa.fullchain.cer" $LOCAL_SSL_DIR

    log "重载本地 Nginx..."
    nginx -s reload
}

# ================== 同步证书 ==================
sync_cert() {
    for host in "${REMOTE_HOSTS[@]}"; do
        log "同步ECDSA证书到 $host..."
        scp "$ACME_DIR/$DOMAIN.key" "$ACME_DIR/$DOMAIN.fullchain.cer" "$host:$REMOTE_SSL_DIR/"
        ssh "$host" "chmod 644 $REMOTE_SSL_DIR/$DOMAIN.key $REMOTE_SSL_DIR/$DOMAIN.fullchain.cer && nginx -s reload"
        log "$host 同步完成"
    done
}

# ================== 主流程 ==================
MODE=${1:-all}

#register_account

case "$MODE" in
    apply)   apply_cert ;;
    install) install_cert ;;
    sync)    sync_cert ;;
    all)
        apply_cert
        install_cert
        sync_cert
        ;;
    *)
        echo "Usage: $0 {apply|install|sync|all}"
        exit 1
esac

log "操作完成: $MODE"
