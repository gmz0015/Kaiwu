# 待定事项

只登记跨模块或产品层面的未决选择。普通问题留在模块 README；所有条目均不阻塞当前基础开发。

| ID | 状态 | 待确定事项 | 影响 | 当前处理 |
| --- | --- | --- | --- | --- |
| OI-001 | 待发布前确定 | Bundle ID、Team、分发渠道 | 签名、helper、CloudKit | 开发标识与本地包 |
| OI-002 | 待引擎接入时确定 | Ghostty 固定版本与封装范围 | ABI、渲染、更新 | 外部启动器 |
| OI-003 | 待引擎分发前确定 | 第三方许可要求及 Mihomo 分发方式 | 源码与二进制交付 | 项目沿用远端 MIT 许可证；未捆绑第三方核心 |
| OI-004 | 待同步开发时确定 | SwiftData/Core Data 或 CKSyncEngine | 迁移、冲突、离线策略 | 同步契约 |
| OI-005 | 待配置 | 维护者审核、CODEOWNERS、分支保护 | PR 审核与合并 | 已确认公开仓库；不创建虚构账号或声明已启用 |

依据：[基础 ADR](decisions/0001-app-foundation.md)、[引擎 ADR](decisions/0002-native-engines.md)、[CloudKit](CLOUDKIT.md)。

新增条目记录问题、涉及模块、阻塞性、证据、选项和下一步。解决后保留条目，写结论与落地位置；讨论结束不等于已经实现。
