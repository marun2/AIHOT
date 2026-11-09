# 本公司部署说明（marun2/AIHOT，均瑶健康）

> 根目录的 `CLAUDE.md` / `AGENTS.md` 属于原作者（KKKKhazix/AIHOT），同步上游时会被覆盖，**不要改它们**；本公司自己的交接说明只写在这个文件（`.claude/CLAUDE.md`，上游没有这个文件，同步不会冲突）。

## 这是什么
- 原作者开源的 AI 热点站框架的 fork，部署为公司内部的 AI 热点站：`https://hot.werdery.net`
- 在企业中台（`marun2/zhongtai`）里登记为**外部托管的通用应用**，由中台的 Caddy 转发并做飞书登录把门（中台 `.env` 的 `EXTERNAL_APPS`）
- 服务器：和中台同一台阿里云 ECS（上海，47.101.169.42），代码在 `/opt/myhot`，容器名 `aihot-*`（`setup-1` 停止是正常的）

## 和用户合作的方式
- 用户不写代码，用中文、讲结果、少术语；由你改代码、跑检查、提交、推送，再一两句话说明改了什么
- 提交信息用中文（我们自己的提交），上游的提交保持原样

## 发布
- 推送到 `main` → Actions「Check」测试通过 → 「部署」SSH 到服务器运行 `deploy/remote-deploy.sh`（拉代码 → 构建 → 重启 → 检查网站）。详见 `deploy/自动部署.md`
- 只改文档时提交信息加 `[skip ci]`，避免无意义的重建
- 服务器上的 `.env`、`docker-compose.override.yml` 不在 Git 里；不要在服务器上直接改代码（部署用 `git pull --ff-only`）
- 同步原作者更新：GitHub 仓库页 Sync fork → Update branch；先看 `docs/deploy.md` 的“更新”一节有没有要手动处理的事

## 我们在上游之外做过的改动（同步上游时注意别丢）
- `.github/workflows/deploy.yml`、`deploy/remote-deploy.sh`、`deploy/自动部署.md`：自动部署（私钥支持 base64 一行）
- `COLLECT_MIN_INTERVAL_MINUTES`：每个信源两次读取的最短间隔（`packages/backend/src/config.ts`、`sources/collect.ts`、`.env.example`、`docs/sources.md`）
- 去掉侧栏和手机顶栏左上角的站名标识（`apps/web/app/components/shell/Sidebar.tsx`、`features/feed/Filters.tsx`）

## 安全约束
- 不要索要或经手密钥：部署私钥只在 GitHub Secrets（`DEPLOY_SSH_KEY`、`DEPLOY_KNOWN_HOSTS`、`DEPLOY_HOST`），服务器 `.env` 由用户自己维护
- 需要在服务器上执行的命令写清楚交给用户执行，不要自己改服务器配置
