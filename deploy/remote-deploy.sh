#!/usr/bin/env bash
# 服务器端部署脚本：拉取最新代码、重新构建镜像、重启服务。
# 由 GitHub Actions 通过 SSH 触发（部署钥匙在 authorized_keys 里被限定只能运行这个脚本），
# 也可以在服务器上手动运行：bash /opt/myhot/deploy/remote-deploy.sh
# 抓海外资源走 .env 里的 EGRESS_PROXY_URL（香港中转），拉 GitHub 代码和构建镜像时也用它。
set -euo pipefail

# 整个流程放在函数里：bash 会先读完函数再执行，git pull 更新本脚本时不会读到一半的新内容。
main() {
  cd /opt/myhot

  # 同一时间只跑一次部署；上一次没跑完时，这一次排队等它结束。
  exec 9>/tmp/myhot-deploy.lock
  flock 9

  local proxy
  proxy="$(grep -E '^EGRESS_PROXY_URL=' .env | head -1 | cut -d= -f2-)"
  if [ -z "$proxy" ]; then
    echo "错误：.env 里没有 EGRESS_PROXY_URL，无法通过香港中转拉取代码。" >&2
    exit 1
  fi

  echo "==> 拉取最新代码"
  git -c http.proxy="$proxy" pull --ff-only origin main
  echo "    当前版本：$(git log -1 --format='%h %s')"

  echo "==> 构建镜像"
  docker compose build \
    --build-arg HTTP_PROXY="$proxy" --build-arg HTTPS_PROXY="$proxy" \
    --build-arg http_proxy="$proxy" --build-arg https_proxy="$proxy"

  echo "==> 重启服务（会先自动跑数据库迁移）"
  AIHOT_RELEASE="$(git rev-parse --short HEAD)" docker compose up -d
  docker image prune -f > /dev/null

  echo "==> 检查网站"
  for _ in $(seq 1 45); do
    if curl -fsS -o /dev/null http://127.0.0.1:3000; then
      echo "部署完成 ✓"
      return 0
    fi
    sleep 2
  done
  echo "网站 90 秒内没有响应，请在服务器上查看：cd /opt/myhot && docker compose logs --tail 50 web api" >&2
  exit 1
}

main "$@"
exit
