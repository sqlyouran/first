```
/opsx:explore

目的：开发城市模块后端（景点需要归属城市，但项目里还没有城市数据）

城市字段：name(必填) / nameZh / coverImage / description / bestSeason

支持列表和详情查询
```

```
/opsx:explore

目的：开发景点模块后端

景点字段（Phase 1基本信息）：
name(必填) / nameZh / description / coverImage
gallery(图片集) / tags(标签) / cityId(归属城市，必填) / status

景点和帖子是多对多关系，需要关联表

支持：列表（分页+城市筛选+排序）+ 详情 + 排行榜（评分/热度/收藏 Top N）
```

```
/opsx:explore

目的：开发景点列表页（mock先行）

1. 定义Spot的TypeScript接口
2. mockSpots.ts，15条景点假数据
3. 列表页：城市筛选 + 排序 + 卡片网格 + 无限滚动
   卡片：封面图 + 评分 + 城市位置 + 中英文名 + 标签
```

```
/opsx:explore

目的：开发景点详情页

1. 图片轮播（gallery多张图）
2. 基础信息展示（两列布局）
3. 复用评论和收藏组件
```