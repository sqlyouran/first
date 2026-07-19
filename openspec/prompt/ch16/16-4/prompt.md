/opsx:explore 首页导航填坑
线上首页像"样板间"：FeatureNav 4 张卡 href 全是 #、顶栏没有主导航、
热门帖子没有"查看全部"。这是我initial 的观察，帮我核实别全信。
请探明：目标列表页存不存在（是接线还是造页）、4 张卡各接哪、
Plan with AI 该指向哪、SiteHeader 桌面/移动怎么处理、会不会踩 Region-Slot 红线。
先别 propose。

ssh 上 ECS，在项目根目录执行：
bash scripts/deploy.sh
（脚本自动 git pull --recurse-submodules + docker compose up -d --build，
 不用手动敲，也不用再动 Nginx / 证书 / 数据库）