我想优化 WanderChina 后端 service 层的测试覆盖：
- 现状：AuthService/PostService/JwtService 等核心 Service 疑似无测试
- 请扫描 service 层，列出哪些 Service 有测试、哪些没有
- 分析未覆盖的核心业务路径，给出补测优先级
- 只做诊断，不要写任何代码