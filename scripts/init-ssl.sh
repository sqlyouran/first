#!/usr/bin/env bash
# Let's Encrypt 证书初始化脚本（首次部署时在 ECS 上执行一次）
# 用法：bash scripts/init-ssl.sh your-domain.com [admin@your-domain.com]
set -euo pipefail

cd "$(dirname "$0")/.."

DOMAIN="${1:-}"
EMAIL="${2:-admin@${DOMAIN}}"

if [ -z "$DOMAIN" ]; then
  echo "用法：bash scripts/init-ssl.sh <domain> [email]" >&2
  exit 1
fi

# ---- 1. 安装 certbot（若不存在）----
if ! command -v certbot >/dev/null 2>&1; then
  echo "→ 安装 certbot..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y certbot
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y certbot
  else
    echo "错误：未识别的包管理器，请手动安装 certbot。" >&2
    exit 1
  fi
fi

# ---- 2. 申请证书（webroot 模式，复用 nginx 的 /var/www/certbot）----
WEBROOT="./nginx/certbot"
mkdir -p "$WEBROOT"
echo "→ 为 $DOMAIN 申请证书..."
sudo certbot certonly --webroot -w "$WEBROOT" \
  -d "$DOMAIN" \
  --email "$EMAIL" --agree-tos --non-interactive

# ---- 3. 拷贝证书到 nginx/ssl/ ----
mkdir -p ./nginx/ssl
sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ./nginx/ssl/fullchain.pem
sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   ./nginx/ssl/privkey.pem
echo "✓ 证书已复制到 nginx/ssl/，重启 nginx 生效：docker compose restart nginx"

# ---- 4. 续期提示 ----
echo ""
echo "证书 90 天到期，续期命令（建议加入 crontab）："
echo "  sudo certbot renew --webroot -w $WEBROOT && \\"
echo "  sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./nginx/ssl/fullchain.pem && \\"
echo "  sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./nginx/ssl/privkey.pem && \\"
echo "  docker compose restart nginx"
