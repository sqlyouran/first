```
/opsx:explore

目的：为帖子详情页补充评论、投票、收藏三个后端功能

1. 评论系统
   - CommentEntity extends BaseEntity
   - postId + userId + content(TEXT) + parentCommentId(可null)
   - parentCommentId=null → 顶层评论
   - parentCommentId=某评论ID → 回复
   - 查询：按postId查顶层评论(分页)，按parentId查回复
   - 发布/回复/删除(软删除)

2. 投票（点赞/点踩）
   - VoteEntity extends BaseEntity
   - postId + userId + voteType枚举(UP/DOWN)
   - @Table uniqueConstraints(post_id, user_id) → 一人一票
   - vote()方法：不存在→创建 / 相同→删除(取消) / 不同→切换
   - getVoteStats(postId) → {upCount, downCount, userVote}

3. 收藏
   - BookmarkEntity extends BaseEntity
   - postId + userId
   - @Table uniqueConstraints(post_id, user_id) → 防重复
   - toggle()：不存在→收藏 / 已存在→取消
   - listBookmarks(userId, 分页)

4. 全部需要JWT认证
   参考PostController的requireUserId()模式
```

```
/opsx:explore

目的：在帖子详情页(posts/[id])添加评论、投票、收藏交互组件

1. 投票按钮组 VoteButtons（Client Component）
   - 👍 upCount | 👎 downCount
   - 登录用户显示当前投票状态（已选项高亮）
   - 乐观更新：先改UI再调API，失败回滚

2. 收藏按钮 BookmarkButton（Client Component）
   - lucide-react: Bookmark / BookmarkCheck
   - 点击切换填充/空心状态
   - 乐观更新

3. 评论区 CommentSection（Client Component）
   - CommentList: 顶层评论列表 + 每条下的回复
   - CommentItem: 头像 + 昵称 + 内容 + 时间 + 回复按钮
   - CommentInput: 底部输入框 + 发布按钮
   - 最多展开2层

4. 参考authFetch + ApiResponse<T>模式
   遵循frontend-conventions + styling-conventions
```