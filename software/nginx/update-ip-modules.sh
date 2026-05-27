#!/bin/bash
set -e

# ================== 基本配置 ==================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_NGINX_CONF="${SCRIPT_DIR}/nginx.conf"
SOURCE_DB_DIR="${SCRIPT_DIR}/ip"
SOURCE_GEOIP2_DB="${SOURCE_DB_DIR}/GeoLite2-City.mmdb"
SOURCE_IP2REGION_DB="${SOURCE_DB_DIR}/ip2region_v4.xdb"

LOCAL_MODULE_DIR="/docker/nginx/ip"
LOCAL_NGINX_CONF="/etc/nginx/nginx.conf"

REMOTE_MODULE_DIR="/docker/nginx/ip"
REMOTE_NGINX_CONF="/etc/nginx/nginx.conf"

REMOTE_HOSTS=("wh-1" "wh-2" "wh-3" "sz-0" "sz-01" "sz-1" "sz-2" "sz-3" "us-2" "us-3" "us-4")

GEOIP2_REPOSITORY="blankhang/geoip2"
IP2REGION_REPOSITORY="blankhang/ip2region"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
FORCE="${FORCE:-false}"
SYNC_IP_DATABASES=true

NGINX_TEST_CMD="${NGINX_TEST_CMD:-nginx -t -c __CONF__}"
NGINX_RELOAD_CMD="${NGINX_RELOAD_CMD:-nginx -s reload}"
REMOTE_NGINX_VERSION_CMD="${REMOTE_NGINX_VERSION_CMD:-nginx -v 2>&1}"
REMOTE_NGINX_TEST_CMD="${REMOTE_NGINX_TEST_CMD:-nginx -t -c __CONF__}"
REMOTE_NGINX_RELOAD_CMD="${REMOTE_NGINX_RELOAD_CMD:-nginx -s reload}"
REMOTE_NGINX_UPGRADE_CMD="${REMOTE_NGINX_UPGRADE_CMD:-}"
REMOTE_NGINX_WAS_UPGRADED="false"

SELECTED_ARCH=""
SELECTED_NGINX_VERSION=""
SELECTED_GEOIP2_TAG=""
SELECTED_GEOIP2_NAME=""
SELECTED_GEOIP2_URL=""
SELECTED_IP2REGION_TAG=""
SELECTED_IP2REGION_NAME=""
SELECTED_IP2REGION_URL=""
WORK_DIR=""

# ================== 工具函数 ==================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

usage() {
    cat <<EOF
Usage: $0 {install|sync|all}

说明:
  install  下载当前架构的最新共同版本模块，更新本机 ${LOCAL_MODULE_DIR} 和 ${LOCAL_NGINX_CONF}
  sync     把本机模块和 nginx.conf 同步到 REMOTE_HOSTS，并校验/重载远端 Nginx
  all      先 install 再 sync

使用前请先编辑脚本顶部配置区:
  TEMPLATE_NGINX_CONF
  SOURCE_DB_DIR
  LOCAL_MODULE_DIR
  LOCAL_NGINX_CONF
  REMOTE_MODULE_DIR
  REMOTE_NGINX_CONF
  REMOTE_HOSTS

可选环境变量:
  GITHUB_TOKEN            GitHub API token，避免匿名访问限流
  FORCE                   设为 true 时即使版本未变化也重新覆盖
  NGINX_TEST_CMD          本机校验命令，使用 __CONF__ 作为配置占位符
  NGINX_RELOAD_CMD        本机重载命令
  REMOTE_NGINX_VERSION_CMD 远端版本检查命令
  REMOTE_NGINX_TEST_CMD   远端校验命令，使用 __CONF__ 作为配置占位符
  REMOTE_NGINX_RELOAD_CMD 远端重载命令
  REMOTE_NGINX_UPGRADE_CMD 远端自定义升级命令，为空时使用内置自动升级逻辑
EOF
}

normalize_arch() {
    case "$1" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "不支持的架构: $1" >&2
            exit 1
            ;;
    esac
}

detect_arch() {
    normalize_arch "$(uname -m)"
}

select_release_assets() {
    local arch="$1"
    local work_dir="$2"
    local requested_version="${3:-}"
    local meta_file="${work_dir}/meta.json"

    python3 - "$GEOIP2_REPOSITORY" "$IP2REGION_REPOSITORY" "$arch" "$GITHUB_TOKEN" "$meta_file" "$requested_version" <<'PY'
import json
import re
import sys
import urllib.request

geoip2_repo, ip2region_repo, arch, token, meta_file, requested_version = sys.argv[1:7]
headers = {
    "Accept": "application/vnd.github+json",
    "User-Agent": "nginx-ip-module-updater",
}
if token:
    headers["Authorization"] = f"Bearer {token}"

def fetch_releases(repository):
    url = f"https://api.github.com/repos/{repository}/releases?per_page=50"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)

def collect_assets(repository, kind):
    prefix = f"nginx-{kind}-nginx-"
    pattern = re.compile(rf"^{re.escape(prefix)}(\d+\.\d+\.\d+)-linux-{arch}\.so$")
    versions = {}
    for release in fetch_releases(repository):
        assets = release.get("assets", [])
        asset_map = {asset.get("name", ""): asset for asset in assets}
        for name, asset in asset_map.items():
            match = pattern.match(name)
            if not match:
                continue
            version = match.group(1)
            sha_name = name + ".sha256"
            sha_asset = asset_map.get(sha_name)
            if not sha_asset:
                continue
            versions[version] = {
                "release_tag": release.get("tag_name", ""),
                "asset_name": name,
                "asset_url": asset["browser_download_url"],
                "sha_name": sha_name,
                "sha_url": sha_asset["browser_download_url"],
            }
    return versions

def version_key(version):
    return tuple(int(part) for part in version.split("."))

geoip2_versions = collect_assets(geoip2_repo, "geoip2")
ip2region_versions = collect_assets(ip2region_repo, "ip2region")
common_versions = sorted(set(geoip2_versions) & set(ip2region_versions), key=version_key)
if not common_versions:
    raise SystemExit("未找到两个模块共同支持的 nginx 版本")

if requested_version:
    if requested_version not in common_versions:
        raise SystemExit(f"未找到与 nginx {requested_version} 完全匹配的双模块 Release")
    selected_version = requested_version
else:
    selected_version = common_versions[-1]
payload = {
    "nginx_version": selected_version,
    "geoip2": geoip2_versions[selected_version],
    "ip2region": ip2region_versions[selected_version],
}

with open(meta_file, "w", encoding="utf-8") as fh:
    json.dump(payload, fh)
PY
}

download_from_meta() {
    local meta_file="$1"
    local module_key="$2"
    local output_file="$3"
    local work_dir="$4"
    local asset_name asset_url sha_name sha_url

    asset_name="$(python3 - "$meta_file" "$module_key" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)[sys.argv[2]]["asset_name"])
PY
)"
    asset_url="$(python3 - "$meta_file" "$module_key" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)[sys.argv[2]]["asset_url"])
PY
)"
    sha_name="$(python3 - "$meta_file" "$module_key" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)[sys.argv[2]]["sha_name"])
PY
)"
    sha_url="$(python3 - "$meta_file" "$module_key" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)[sys.argv[2]]["sha_url"])
PY
)"

    local download_headers=()
    if [ -n "$GITHUB_TOKEN" ]; then
        download_headers=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi

    log "下载 ${module_key}:${asset_name}"
    curl -fsSL "${download_headers[@]}" -o "${work_dir}/${asset_name}" "$asset_url"
    curl -fsSL "${download_headers[@]}" -o "${work_dir}/${sha_name}" "$sha_url"
    (cd "$work_dir" && sha256sum -c "$sha_name" >/dev/null)

    install -m 0644 "${work_dir}/${asset_name}" "$output_file"
    printf '%s\n' "$asset_name"
}

update_nginx_conf() {
    local template_conf="$1"
    local module_dir="$2"
    local geoip2_name="$3"
    local ip2region_name="$4"
    local output_path="$5"

    python3 - "$template_conf" "$module_dir" "$geoip2_name" "$ip2region_name" "$output_path" <<'PY'
import pathlib
import re
import sys

template_conf, module_dir, geoip2_name, ip2region_name, output_path = sys.argv[1:6]
source = pathlib.Path(template_conf).read_text(encoding="utf-8")

managed_block_re = re.compile(
    r"(?ms)^# BEGIN managed nginx ip modules\n.*?^# END managed nginx ip modules\n?"
)
module_line_re = re.compile(
    rf"^load_module\s+{re.escape(module_dir)}/[^\n;]*(?:geoip2|ip2region)[^\n;]*;\n?",
    re.M,
)
comment_re = re.compile(
    r"^# 如果是动态模块需要使用 load_module 的方式来加载它\s*\n?",
    re.M,
)

body = managed_block_re.sub("", source)
body = module_line_re.sub("", body)
body = comment_re.sub("", body)
body = body.lstrip("\n")

block = (
    "# BEGIN managed nginx ip modules\n"
    "# 如果是动态模块需要使用 load_module 的方式来加载它\n"
    f"load_module {module_dir}/{geoip2_name};\n"
    f"load_module {module_dir}/{ip2region_name};\n"
    "# END managed nginx ip modules\n\n"
)

pathlib.Path(output_path).write_text(block + body, encoding="utf-8")
PY
}

run_cmd_with_conf() {
    local cmd_template="$1"
    local conf_path="$2"
    local cmd="${cmd_template//__CONF__/$conf_path}"
    bash -lc "$cmd"
}

has_local_systemd_nginx() {
    command -v systemctl >/dev/null 2>&1 && { systemctl cat nginx >/dev/null 2>&1 || systemctl cat nginx.service >/dev/null 2>&1; }
}

recover_local_nginx_port_conflict() {
    local pids=""

    if command -v ss >/dev/null 2>&1; then
        pids="$(ss -ltnp '( sport = :80 or sport = :443 )' 2>/dev/null | awk -F'pid=' '/nginx/ {split($2,a,","); print a[1]}' | sort -u | xargs || true)"
    elif command -v lsof >/dev/null 2>&1; then
        pids="$(lsof -t -iTCP:80 -sTCP:LISTEN 2>/dev/null; lsof -t -iTCP:443 -sTCP:LISTEN 2>/dev/null)"; pids="$(printf '%s\n' "$pids" | sort -u | xargs || true)"
    fi

    [ -z "$pids" ] && return 1

    log "检测到本地 nginx 残留进程占用 80/443，尝试清理: $pids"
    kill -QUIT $pids 2>/dev/null || true
    sleep 2

    if command -v ss >/dev/null 2>&1 && ss -ltnp '( sport = :80 or sport = :443 )' 2>/dev/null | grep -q nginx; then
        log "本地 nginx 残留进程仍占用端口，执行强制终止: $pids"
        kill -TERM $pids 2>/dev/null || true
        sleep 2
        kill -KILL $pids 2>/dev/null || true
    fi
    return 0
}

apply_local_nginx() {
    local mode="$1"

    if has_local_systemd_nginx; then
        systemctl daemon-reload >/dev/null 2>&1 || true
        if [ "$mode" = "restart" ]; then
            systemctl restart nginx || {
                recover_local_nginx_port_conflict && systemctl restart nginx;
            } || systemctl reload nginx || bash -lc "$NGINX_RELOAD_CMD"
        else
            systemctl reload nginx || systemctl restart nginx || {
                recover_local_nginx_port_conflict && systemctl restart nginx;
            } || bash -lc "$NGINX_RELOAD_CMD"
        fi
    else
        bash -lc "$NGINX_RELOAD_CMD"
    fi
}

apply_remote_nginx() {
    local host="$1"
    local mode="$2"
    local test_cmd="$3"
    local reload_cmd="$4"
    local q_mode q_test q_reload

    printf -v q_mode '%q' "$mode"
    printf -v q_test '%q' "$test_cmd"
    printf -v q_reload '%q' "$reload_cmd"

    ssh "$host" "MODE=${q_mode} TEST_CMD=${q_test} RELOAD_CMD=${q_reload} bash -s" <<'EOF'
set -e

MODE="${MODE:-reload}"
TEST_CMD="${TEST_CMD:-}"
RELOAD_CMD="${RELOAD_CMD:-}"

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

HAS_SYSTEMD=0
if command -v systemctl >/dev/null 2>&1 && { systemctl cat nginx >/dev/null 2>&1 || systemctl cat nginx.service >/dev/null 2>&1; }; then
    HAS_SYSTEMD=1
fi

run_remote_cmd() {
    CMD="$1"
    [ -n "$CMD" ] || return 1
    bash -lc "$CMD"
}

recover_remote_conflict() {
    PIDS=""
    if command -v ss >/dev/null 2>&1; then
        PIDS="$(ss -ltnp '( sport = :80 or sport = :443 )' 2>/dev/null | awk -F'pid=' '/nginx/ {split($2,a,","); print a[1]}' | sort -u | xargs || true)"
    elif command -v lsof >/dev/null 2>&1; then
        PIDS="$(lsof -t -iTCP:80 -sTCP:LISTEN 2>/dev/null; lsof -t -iTCP:443 -sTCP:LISTEN 2>/dev/null)"; PIDS="$(printf '%s\n' "$PIDS" | sort -u | xargs || true)"
    fi

    [ -z "$PIDS" ] && return 1

    echo "[remote] 检测到 nginx 残留进程占用 80/443，尝试清理: $PIDS"
    $SUDO kill -QUIT $PIDS 2>/dev/null || true
    sleep 2

    if command -v ss >/dev/null 2>&1 && ss -ltnp '( sport = :80 or sport = :443 )' 2>/dev/null | grep -q nginx; then
        echo "[remote] nginx 残留进程仍占用端口，执行强制终止: $PIDS"
        $SUDO kill -TERM $PIDS 2>/dev/null || true
        sleep 2
        $SUDO kill -KILL $PIDS 2>/dev/null || true
    fi
    return 0
}

run_remote_cmd "$TEST_CMD"

if [ "$HAS_SYSTEMD" -eq 1 ]; then
    $SUDO systemctl daemon-reload >/dev/null 2>&1 || true
    if [ "$MODE" = "restart" ]; then
        $SUDO systemctl restart nginx || {
            recover_remote_conflict && $SUDO systemctl restart nginx;
        } || $SUDO systemctl reload nginx || run_remote_cmd "$RELOAD_CMD"
    else
        $SUDO systemctl reload nginx || $SUDO systemctl restart nginx || {
            recover_remote_conflict && $SUDO systemctl restart nginx;
        } || run_remote_cmd "$RELOAD_CMD"
    fi
else
    run_remote_cmd "$RELOAD_CMD"
fi
EOF
}

resolve_selected_versions() {
    if [ -n "$SELECTED_NGINX_VERSION" ] && [ -n "$WORK_DIR" ] && [ -f "${WORK_DIR}/meta.json" ]; then
        return
    fi

    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "$WORK_DIR"' EXIT

    SELECTED_ARCH="$(detect_arch)"
    select_release_assets "$SELECTED_ARCH" "$WORK_DIR"

    local meta_file="${WORK_DIR}/meta.json"
    SELECTED_NGINX_VERSION="$(python3 - "$meta_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["nginx_version"])
PY
)"
    SELECTED_GEOIP2_NAME="$(python3 - "$meta_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["geoip2"]["asset_name"])
PY
)"
    SELECTED_GEOIP2_TAG="$(python3 - "$meta_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["geoip2"]["release_tag"])
PY
)"
    SELECTED_GEOIP2_URL="$(python3 - "$meta_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["geoip2"]["asset_url"])
PY
)"
    SELECTED_IP2REGION_NAME="$(python3 - "$meta_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["ip2region"]["asset_name"])
PY
)"
    SELECTED_IP2REGION_TAG="$(python3 - "$meta_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["ip2region"]["release_tag"])
PY
)"
    SELECTED_IP2REGION_URL="$(python3 - "$meta_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["ip2region"]["asset_url"])
PY
)"

    log "当前架构: ${SELECTED_ARCH}"
    log "选择共同 nginx 版本: ${SELECTED_NGINX_VERSION}"
    log "geoip2 release: ${GEOIP2_REPOSITORY} @ ${SELECTED_GEOIP2_TAG}"
    log "geoip2 asset: ${SELECTED_GEOIP2_NAME}"
    log "geoip2 url: ${SELECTED_GEOIP2_URL}"
    log "ip2region release: ${IP2REGION_REPOSITORY} @ ${SELECTED_IP2REGION_TAG}"
    log "ip2region asset: ${SELECTED_IP2REGION_NAME}"
    log "ip2region url: ${SELECTED_IP2REGION_URL}"
}

json_field() {
    local meta_file="$1"
    local path="$2"
    python3 - "$meta_file" "$path" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    value = json.load(fh)
for part in sys.argv[2].split("."):
    value = value[part]
print(value)
PY
}

extract_version() {
    python3 - "$1" <<'PY'
import re, sys
match = re.search(r'(\d+\.\d+\.\d+)', sys.argv[1])
if match:
    print(match.group(1))
PY
}

version_lt() {
    python3 - "$1" "$2" <<'PY'
import sys
a = tuple(map(int, sys.argv[1].split(".")))
b = tuple(map(int, sys.argv[2].split(".")))
raise SystemExit(0 if a < b else 1)
PY
}

get_remote_arch() {
    local host="$1"
    local raw_arch
    raw_arch="$(ssh "$host" "uname -m")"
    normalize_arch "$raw_arch"
}

get_remote_nginx_version() {
    local host="$1"
    local output
    output="$(ssh "$host" "$REMOTE_NGINX_VERSION_CMD" 2>&1 || true)"
    extract_version "$output"
}

get_remote_nginx_candidate_version() {
    local host="$1"
    local output

    if [ -n "$REMOTE_NGINX_UPGRADE_CMD" ]; then
        return 0
    fi

    output="$(ssh "$host" 'bash -s' <<'EOF'
set -e

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update >/dev/null
    $SUDO apt-get install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring ubuntu-keyring >/dev/null

    if [ ! -f /usr/share/keyrings/nginx-archive-keyring.gpg ]; then
        curl -fsSL https://nginx.org/keys/nginx_signing.key | $SUDO gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg
    fi

    . /etc/os-release
    CODENAME="${VERSION_CODENAME:-}"
    if [ -z "$CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
        CODENAME="$(lsb_release -cs)"
    fi
    if [ -z "$CODENAME" ]; then
        exit 0
    fi

    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/mainline/${ID} ${CODENAME} nginx" | $SUDO tee /etc/apt/sources.list.d/nginx.list >/dev/null
    $SUDO apt-get update >/dev/null
    apt-cache policy nginx | awk "/Candidate:/ {print \$2}" | head -n1
elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y yum-utils >/dev/null
    $SUDO tee /etc/yum.repos.d/nginx.repo >/dev/null <<'REPO'
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
REPO
    dnf --showduplicates list nginx 2>/dev/null | awk '/^nginx[[:space:]]/ {print $2}' | sed 's/^[0-9]*://' | cut -d- -f1 | sort -V | tail -n1
elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y yum-utils >/dev/null
    $SUDO tee /etc/yum.repos.d/nginx.repo >/dev/null <<'REPO'
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
REPO
    yum --showduplicates list nginx 2>/dev/null | awk '/^nginx[[:space:]]/ {print $2}' | sed 's/^[0-9]*://' | cut -d- -f1 | sort -V | tail -n1
fi
EOF
)"
    extract_version "$output"
}

upgrade_remote_nginx_auto() {
    local host="$1"
    ssh "$host" 'bash -s' <<'EOF'
set -e

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

if command -v apt-get >/dev/null 2>&1; then
    HELD_NGINX_PACKAGES="$($SUDO apt-mark showhold 2>/dev/null | awk '/^nginx($|-)/ {print $1}' | xargs || true)"
    $SUDO apt-get update
    $SUDO apt-get install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring ubuntu-keyring

    if [ ! -f /usr/share/keyrings/nginx-archive-keyring.gpg ]; then
        curl -fsSL https://nginx.org/keys/nginx_signing.key | $SUDO gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg
    fi

    . /etc/os-release
    CODENAME="${VERSION_CODENAME:-}"
    if [ -z "$CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
        CODENAME="$(lsb_release -cs)"
    fi
    if [ -z "$CODENAME" ]; then
        echo "无法识别系统 codename" >&2
        exit 1
    fi

    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/mainline/${ID} ${CODENAME} nginx" | $SUDO tee /etc/apt/sources.list.d/nginx.list >/dev/null
    $SUDO apt-get update
    if [ -n "$HELD_NGINX_PACKAGES" ]; then
        $SUDO apt-mark unhold $HELD_NGINX_PACKAGES >/dev/null 2>&1 || true
    fi
    $SUDO apt-get install -y --allow-change-held-packages nginx
    if [ -n "$HELD_NGINX_PACKAGES" ]; then
        $SUDO apt-mark hold $HELD_NGINX_PACKAGES >/dev/null 2>&1 || true
    fi
    if command -v systemctl >/dev/null 2>&1; then
        $SUDO systemctl daemon-reload >/dev/null 2>&1 || true
        $SUDO systemctl enable nginx >/dev/null 2>&1 || true
    fi
elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y yum-utils
    $SUDO tee /etc/yum.repos.d/nginx.repo >/dev/null <<'REPO'
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
REPO
    $SUDO dnf install -y nginx
    if command -v systemctl >/dev/null 2>&1; then
        $SUDO systemctl daemon-reload >/dev/null 2>&1 || true
        $SUDO systemctl enable nginx >/dev/null 2>&1 || true
    fi
elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y yum-utils
    $SUDO tee /etc/yum.repos.d/nginx.repo >/dev/null <<'REPO'
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
REPO
    $SUDO yum install -y nginx
    if command -v systemctl >/dev/null 2>&1; then
        $SUDO systemctl daemon-reload >/dev/null 2>&1 || true
        $SUDO systemctl enable nginx >/dev/null 2>&1 || true
    fi
else
    echo "未支持的远端包管理器，请配置 REMOTE_NGINX_UPGRADE_CMD" >&2
    exit 1
fi
EOF
}

ensure_remote_nginx_version() {
    local host="$1"
    local target_version="$2"
    local remote_arch="$3"
    local current_version
    local candidate_version
    local candidate_work_dir

    REMOTE_NGINX_WAS_UPGRADED="false"
    current_version="$(get_remote_nginx_version "$host")"
    if [ -z "$current_version" ]; then
        log "${host} 未检测到 nginx 版本，尝试先升级"
    else
        log "${host} 当前 nginx 版本: ${current_version}"
        if ! version_lt "$current_version" "$target_version"; then
            log "${host} nginx 版本已满足插件要求"
            return
        fi
    fi

    candidate_version="$(get_remote_nginx_candidate_version "$host")"
    if [ -n "$candidate_version" ]; then
        log "${host} 软件源候选 nginx 版本: ${candidate_version}"
        if version_lt "$candidate_version" "$target_version"; then
            candidate_work_dir="$(mktemp -d)"
            if select_release_assets "$remote_arch" "$candidate_work_dir" "$candidate_version"; then
                log "${host} 虽拿不到最新 ${target_version}，但可升级到有匹配插件的 ${candidate_version}"
            else
                log "${host} 软件源当前只能提供 ${candidate_version}，且无完全匹配插件；跳过升级与切换"
                rm -rf "$candidate_work_dir"
                return
            fi
            rm -rf "$candidate_work_dir"
        fi
    fi

    log "${host} nginx 版本低于插件要求 ${target_version}，开始升级"
    REMOTE_NGINX_WAS_UPGRADED="true"
    if [ -n "$REMOTE_NGINX_UPGRADE_CMD" ]; then
        ssh "$host" "${REMOTE_NGINX_UPGRADE_CMD//__TARGET_VERSION__/$target_version}"
    else
        upgrade_remote_nginx_auto "$host"
    fi

    current_version="$(get_remote_nginx_version "$host")"
    if [ -z "$current_version" ]; then
        echo "${host} 升级后仍无法识别 nginx 版本" >&2
        exit 1
    fi
    if version_lt "$current_version" "$target_version"; then
        echo "${host} 升级后 nginx 版本仍为 ${current_version}，低于目标 ${target_version}" >&2
        exit 1
    fi

    log "${host} nginx 已升级到 ${current_version}"
}

current_modules_match() {
    [ -f "${LOCAL_MODULE_DIR}/${SELECTED_GEOIP2_NAME}" ] && \
    [ -f "${LOCAL_MODULE_DIR}/${SELECTED_IP2REGION_NAME}" ] && \
    grep -Fq "load_module ${LOCAL_MODULE_DIR}/${SELECTED_GEOIP2_NAME};" "${LOCAL_NGINX_CONF}" && \
    grep -Fq "load_module ${LOCAL_MODULE_DIR}/${SELECTED_IP2REGION_NAME};" "${LOCAL_NGINX_CONF}"
}

remote_modules_match() {
    local host="$1"
    local remote_module_dir="$2"
    local remote_conf="$3"
    local geoip2_name="$4"
    local ip2region_name="$5"

    ssh "$host" "test -f '${remote_module_dir}/${geoip2_name}' && test -f '${remote_module_dir}/${ip2region_name}' && grep -Fq 'load_module ${remote_module_dir}/${geoip2_name};' '${remote_conf}' && grep -Fq 'load_module ${remote_module_dir}/${ip2region_name};' '${remote_conf}'"
}

file_size() {
    if [ -f "$1" ]; then
        wc -c < "$1" | tr -d '[:space:]'
    fi
}

remote_file_size() {
    local host="$1"
    local path="$2"
    ssh "$host" "if [ -f '$path' ]; then wc -c < '$path'; fi" 2>/dev/null | tr -d '[:space:]'
}

sync_local_db_file() {
    local source_file="$1"
    local target_file="$2"
    local label="$3"
    local source_size target_size

    if [ ! -f "$source_file" ]; then
        echo "数据库源文件不存在: $source_file" >&2
        exit 1
    fi

    source_size="$(file_size "$source_file")"
    target_size="$(file_size "$target_file")"
    if [ "$FORCE" = "true" ] || [ ! -f "$target_file" ] || [ "$source_size" != "$target_size" ]; then
        install -m 0644 "$source_file" "$target_file"
        log "已更新本地 ${label}: ${target_file}"
        return 0
    fi
    return 1
}

sync_remote_db_file() {
    local host="$1"
    local source_file="$2"
    local target_file="$3"
    local label="$4"
    local source_size remote_size

    if [ ! -f "$source_file" ]; then
        echo "数据库源文件不存在: $source_file" >&2
        exit 1
    fi

    source_size="$(file_size "$source_file")"
    remote_size="$(remote_file_size "$host" "$target_file")"
    if [ "$FORCE" = "true" ] || [ -z "$remote_size" ] || [ "$source_size" != "$remote_size" ]; then
        scp "$source_file" "$host:${target_file}"
        log "${host} 已更新 ${label}: ${target_file}"
        return 0
    fi
    return 1
}

local_db_files_match() {
    [ -f "$SOURCE_GEOIP2_DB" ] && \
    [ -f "$SOURCE_IP2REGION_DB" ] && \
    [ "$(file_size "$SOURCE_GEOIP2_DB")" = "$(file_size "${LOCAL_MODULE_DIR}/GeoLite2-City.mmdb")" ] && \
    [ "$(file_size "$SOURCE_IP2REGION_DB")" = "$(file_size "${LOCAL_MODULE_DIR}/ip2region_v4.xdb")" ]
}

remote_db_files_match() {
    local host="$1"
    [ -f "$SOURCE_GEOIP2_DB" ] && \
    [ -f "$SOURCE_IP2REGION_DB" ] && \
    [ "$(file_size "$SOURCE_GEOIP2_DB")" = "$(remote_file_size "$host" "${REMOTE_MODULE_DIR}/GeoLite2-City.mmdb")" ] && \
    [ "$(file_size "$SOURCE_IP2REGION_DB")" = "$(remote_file_size "$host" "${REMOTE_MODULE_DIR}/ip2region_v4.xdb")" ]
}

# ================== 安装本机模块 ==================
install_modules() {
    local tmp_conf backup_conf meta_file db_changed=0

    resolve_selected_versions

    mkdir -p "$LOCAL_MODULE_DIR"
    if [ ! -f "$TEMPLATE_NGINX_CONF" ]; then
        echo "nginx 配置模板不存在: $TEMPLATE_NGINX_CONF" >&2
        exit 1
    fi

    if [ "$FORCE" != "true" ] && current_modules_match && { [ "$SYNC_IP_DATABASES" != "true" ] || local_db_files_match; }; then
        log "本机已是目标版本，跳过安装"
        return
    fi

    meta_file="${WORK_DIR}/meta.json"
    download_from_meta "$meta_file" "geoip2" "${LOCAL_MODULE_DIR}/placeholder-geoip2.so" "$WORK_DIR" >/dev/null
    mv "${LOCAL_MODULE_DIR}/placeholder-geoip2.so" "${LOCAL_MODULE_DIR}/${SELECTED_GEOIP2_NAME}"

    download_from_meta "$meta_file" "ip2region" "${LOCAL_MODULE_DIR}/placeholder-ip2region.so" "$WORK_DIR" >/dev/null
    mv "${LOCAL_MODULE_DIR}/placeholder-ip2region.so" "${LOCAL_MODULE_DIR}/${SELECTED_IP2REGION_NAME}"

    if [ "$SYNC_IP_DATABASES" = "true" ]; then
        if sync_local_db_file "$SOURCE_GEOIP2_DB" "${LOCAL_MODULE_DIR}/GeoLite2-City.mmdb" "GeoLite2 数据库"; then
            db_changed=1
        fi
        if sync_local_db_file "$SOURCE_IP2REGION_DB" "${LOCAL_MODULE_DIR}/ip2region_v4.xdb" "ip2region 数据库"; then
            db_changed=1
        fi
    fi

    tmp_conf="${WORK_DIR}/nginx.conf"
    update_nginx_conf "$TEMPLATE_NGINX_CONF" "$LOCAL_MODULE_DIR" "$SELECTED_GEOIP2_NAME" "$SELECTED_IP2REGION_NAME" "$tmp_conf"

    log "校验本地 Nginx 配置"
    run_cmd_with_conf "$NGINX_TEST_CMD" "$tmp_conf"

    backup_conf="${LOCAL_NGINX_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    if [ -f "$LOCAL_NGINX_CONF" ]; then
        cp "$LOCAL_NGINX_CONF" "$backup_conf"
        log "配置备份: ${backup_conf}"
    else
        log "本地目标配置不存在，将直接创建: ${LOCAL_NGINX_CONF}"
    fi
    install -m 0644 "$tmp_conf" "$LOCAL_NGINX_CONF"
    log "已更新本地配置: ${LOCAL_NGINX_CONF}"

    log "应用本地 Nginx 配置"
    apply_local_nginx reload

    log "本机安装完成: nginx=${SELECTED_NGINX_VERSION}"
    log "geoip2 模块: ${LOCAL_MODULE_DIR}/${SELECTED_GEOIP2_NAME}"
    log "ip2region 模块: ${LOCAL_MODULE_DIR}/${SELECTED_IP2REGION_NAME}"
}

# ================== 同步到远端 ==================
sync_modules() {
    local host remote_test_cmd remote_arch host_work_dir host_meta_file
    local host_target_version host_geoip2_name host_geoip2_tag host_geoip2_url
    local host_ip2region_name host_ip2region_tag host_ip2region_url host_conf
    local host_geoip2_local host_ip2region_local
    local remote_current_version active_work_dir active_meta_file
    local active_geoip2_name active_ip2region_name active_geoip2_local active_ip2region_local

    if [ "${#REMOTE_HOSTS[@]}" -eq 0 ]; then
        log "未配置 REMOTE_HOSTS，跳过同步"
        return
    fi

    if [ ! -f "${TEMPLATE_NGINX_CONF}" ]; then
        echo "nginx 配置模板不存在: ${TEMPLATE_NGINX_CONF}" >&2
        exit 1
    fi

    for host in "${REMOTE_HOSTS[@]}"; do
        remote_arch="$(get_remote_arch "$host")"
        host_work_dir="$(mktemp -d)"
        trap 'rm -rf "$WORK_DIR" "$host_work_dir"' EXIT

        select_release_assets "$remote_arch" "$host_work_dir"
        host_meta_file="${host_work_dir}/meta.json"
        host_target_version="$(json_field "$host_meta_file" "nginx_version")"
        host_geoip2_name="$(json_field "$host_meta_file" "geoip2.asset_name")"
        host_geoip2_tag="$(json_field "$host_meta_file" "geoip2.release_tag")"
        host_geoip2_url="$(json_field "$host_meta_file" "geoip2.asset_url")"
        host_ip2region_name="$(json_field "$host_meta_file" "ip2region.asset_name")"
        host_ip2region_tag="$(json_field "$host_meta_file" "ip2region.release_tag")"
        host_ip2region_url="$(json_field "$host_meta_file" "ip2region.asset_url")"

        log "同步模块到 ${host}..."
        log "${host} 架构: ${remote_arch}"
        log "${host} 目标 nginx 版本: ${host_target_version}"
        log "${host} geoip2 release: ${GEOIP2_REPOSITORY} @ ${host_geoip2_tag}"
        log "${host} geoip2 url: ${host_geoip2_url}"
        log "${host} ip2region release: ${IP2REGION_REPOSITORY} @ ${host_ip2region_tag}"
        log "${host} ip2region url: ${host_ip2region_url}"

        ensure_remote_nginx_version "$host" "$host_target_version" "$remote_arch"
        remote_current_version="$(get_remote_nginx_version "$host")"
        log "${host} 当前可用 nginx 版本: ${remote_current_version}"

        active_work_dir="$(mktemp -d)"
        if select_release_assets "$remote_arch" "$active_work_dir" "$remote_current_version"; then
            active_meta_file="${active_work_dir}/meta.json"
            active_geoip2_name="$(json_field "$active_meta_file" "geoip2.asset_name")"
            active_ip2region_name="$(json_field "$active_meta_file" "ip2region.asset_name")"

            if [ "$FORCE" != "true" ] && [ "$active_geoip2_name" = "$host_geoip2_name" ] && [ "$active_ip2region_name" = "$host_ip2region_name" ] && remote_modules_match "$host" "$REMOTE_MODULE_DIR" "$REMOTE_NGINX_CONF" "$active_geoip2_name" "$active_ip2region_name" && { [ "$SYNC_IP_DATABASES" != "true" ] || remote_db_files_match "$host"; }; then
                log "${host} 已经是目标插件版本且配置已生效，跳过同步"
                rm -rf "$host_work_dir"
                rm -rf "$active_work_dir"
                continue
            fi

            host_geoip2_local="${host_work_dir}/payload-geoip2.so"
            host_ip2region_local="${host_work_dir}/payload-ip2region.so"
            download_from_meta "$host_meta_file" "geoip2" "${host_geoip2_local}" "$host_work_dir" >/dev/null
            download_from_meta "$host_meta_file" "ip2region" "${host_ip2region_local}" "$host_work_dir" >/dev/null

            ssh "$host" "mkdir -p '${REMOTE_MODULE_DIR}'"
            scp "${host_geoip2_local}" "$host:${REMOTE_MODULE_DIR}/${host_geoip2_name}"
            scp "${host_ip2region_local}" "$host:${REMOTE_MODULE_DIR}/${host_ip2region_name}"
            if [ "$SYNC_IP_DATABASES" = "true" ]; then
                sync_remote_db_file "$host" "$SOURCE_GEOIP2_DB" "${REMOTE_MODULE_DIR}/GeoLite2-City.mmdb" "GeoLite2 数据库" >/dev/null || true
                sync_remote_db_file "$host" "$SOURCE_IP2REGION_DB" "${REMOTE_MODULE_DIR}/ip2region_v4.xdb" "ip2region 数据库" >/dev/null || true
            fi

            if [ "$active_geoip2_name" != "$host_geoip2_name" ]; then
                active_geoip2_local="${active_work_dir}/payload-geoip2.so"
                download_from_meta "$active_meta_file" "geoip2" "${active_geoip2_local}" "$active_work_dir" >/dev/null
                scp "${active_geoip2_local}" "$host:${REMOTE_MODULE_DIR}/${active_geoip2_name}"
            fi

            if [ "$active_ip2region_name" != "$host_ip2region_name" ]; then
                active_ip2region_local="${active_work_dir}/payload-ip2region.so"
                download_from_meta "$active_meta_file" "ip2region" "${active_ip2region_local}" "$active_work_dir" >/dev/null
                scp "${active_ip2region_local}" "$host:${REMOTE_MODULE_DIR}/${active_ip2region_name}"
            fi

            host_conf="${host_work_dir}/nginx.conf"
            update_nginx_conf "$TEMPLATE_NGINX_CONF" "$REMOTE_MODULE_DIR" "$active_geoip2_name" "$active_ip2region_name" "$host_conf"
            scp "${host_conf}" "$host:${REMOTE_NGINX_CONF}"

            remote_test_cmd="${REMOTE_NGINX_TEST_CMD//__CONF__/${REMOTE_NGINX_CONF}}"
            ssh "$host" "chmod 644 '${REMOTE_MODULE_DIR}/${host_geoip2_name}' '${REMOTE_MODULE_DIR}/${host_ip2region_name}' '${REMOTE_MODULE_DIR}/${active_geoip2_name}' '${REMOTE_MODULE_DIR}/${active_ip2region_name}' '${REMOTE_NGINX_CONF}'"
            if [ "$REMOTE_NGINX_WAS_UPGRADED" = "true" ]; then
                apply_remote_nginx "$host" restart "$remote_test_cmd" "$REMOTE_NGINX_RELOAD_CMD"
            else
                apply_remote_nginx "$host" reload "$remote_test_cmd" "$REMOTE_NGINX_RELOAD_CMD"
            fi
            log "${host} 已切换到匹配 nginx ${remote_current_version} 的插件版本"
        else
            log "${host} 当前 nginx ${remote_current_version} 仍无完全匹配的双模块 Release"
            log "${host} 仅同步了最新插件文件，保留远端现有 nginx.conf，不执行 reload"

            host_geoip2_local="${host_work_dir}/payload-geoip2.so"
            host_ip2region_local="${host_work_dir}/payload-ip2region.so"
            download_from_meta "$host_meta_file" "geoip2" "${host_geoip2_local}" "$host_work_dir" >/dev/null
            download_from_meta "$host_meta_file" "ip2region" "${host_ip2region_local}" "$host_work_dir" >/dev/null

            ssh "$host" "mkdir -p '${REMOTE_MODULE_DIR}'"
            scp "${host_geoip2_local}" "$host:${REMOTE_MODULE_DIR}/${host_geoip2_name}"
            scp "${host_ip2region_local}" "$host:${REMOTE_MODULE_DIR}/${host_ip2region_name}"
            if [ "$SYNC_IP_DATABASES" = "true" ]; then
                sync_remote_db_file "$host" "$SOURCE_GEOIP2_DB" "${REMOTE_MODULE_DIR}/GeoLite2-City.mmdb" "GeoLite2 数据库" >/dev/null || true
                sync_remote_db_file "$host" "$SOURCE_IP2REGION_DB" "${REMOTE_MODULE_DIR}/ip2region_v4.xdb" "ip2region 数据库" >/dev/null || true
            fi
        fi

        log "${host} 同步完成"

        rm -rf "$host_work_dir"
        rm -rf "$active_work_dir"
    done
}

# ================== 主流程 ==================
MODE="${1:-all}"

case "$MODE" in
    install)
        install_modules
        ;;
    sync)
        sync_modules
        ;;
    all)
        install_modules
        sync_modules
        ;;
    *)
        usage
        exit 1
        ;;
esac

log "操作完成: ${MODE}"
