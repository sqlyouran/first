我要在阿里云买一台 ECS，部署个人全栈项目。技术栈：Next.js 16 SSR 前端、Spring Boot 3.3.5 后端、Redis、Nginx，用 Docker Compose 跑在同一台机器上；数据库另用云 RDS 托管，不占这台机器。项目主要给境外用户使用，想免 ICP 备案。请推荐：① 规格（CPU/内存/带宽）；② 操作系统镜像；③ 计费方式；④ 地域节点。每项给理由和大致月成本。


我要把后端数据库连接从本地 MySQL 切到阿里云 RDS，application.yml 现在把 localhost 地址写死了。想探讨怎么用环境变量注入，让本地开发、本地演示（RDS 公网）、生产（RDS 内网）共用一份配置。先只探索、别实现。