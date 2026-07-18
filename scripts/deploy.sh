#!/usr/bin/env bash
# WanderChina 一键部署脚本（在 ECS 服务器项目根目录执行）
# 用法：bash scripts/deploy.sh
set -euo pipefail

cd "$(dirname "$0")/.."

ENV_FILE=".env.production"

# ---- 1. 环境校验 ----
if [ ! -f "$ENV_FILE" ]; then
  echo "错误：缺少 $ENV_FILE。请先执行 cp .env.production.example .env.production 并填入真实值。" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

REQUIRED_VARS=(DB_HOST JWT_SECRET CORS_ALLOWED_ORIGINS DASHSCOPE_API_KEY)
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "错误：$ENV_FILE 中必需变量 $var 未设置。" >&2
    exit 1
  fi
done
echo "✓ 环境变量校验通过"

# ---- 2. 拉取最新代码（含 submodule）----
if [ -d .git ]; then
  echo "→ 拉取最新代码..."
  git pull --recurse-submodules
  git submodule update --init --recursive
fi

# ---- 3. 构建并重启服务 ----
echo "→ 构建镜像并重启服务..."
docker compose --env-file "$ENV_FILE" up -d --build

echo "✓ 部署完成。查看日志：docker compose logs -f"
