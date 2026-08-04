/opsx:explore 
为 WanderChina 的 auth 模块生成 Spec 文档。核心约束：①安全边界 ——Response 禁止包含 password_hash/salt/verification_code；②状态机 —— 用户有 active/locked/deleted/email_unverified 四种状态，分别对应 200/423/401/403 响应码。