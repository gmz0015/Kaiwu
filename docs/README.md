# 文档地图

| 要解决的问题 | 入口 |
| --- | --- |
| 新成员或 agent 开工 | [AGENTS](../AGENTS.md)、[开发规范](../CONTRIBUTING.md) |
| 功能属于哪一层 | [架构](ARCHITECTURE.md)、[工作流边界](WORKSTREAMS.md) |
| 本次要跑什么验证 | [测试与完成标准](TESTING.md) |
| 当前已做到哪里 | [模块目录](../Sources)、[工具检查器](../Tools/RepositoryChecks/README.md) 中的 README |
| 下一阶段优先做什么 | [路线图](ROADMAP.md) |
| 尚未确定的跨模块问题 | [待定事项](OPEN-ITEMS.md) |
| 为何选择当前方案 | [基础 ADR](decisions/0001-app-foundation.md)、[引擎 ADR](decisions/0002-native-engines.md)、[工程规范 ADR](decisions/0003-engineering-foundation.md) |
| 网络恢复与 CloudKit | [恢复设计](NETWORK-RECOVERY.md)、[CloudKit](CLOUDKIT.md) |
| 打包、签名、发布 | [发布说明](RELEASING.md) |
| 向公开仓库提交、推送 | [公开仓库审查](PUBLIC-REVIEW.md) |
| 已取得哪些验证证据 | [验证记录](VALIDATION.md) |
| 设计或交接模板 | [ADR](templates/ADR.md)、[模块 README](templates/MODULE-README.md)、[任务交接](templates/HANDOFF.md) |

文档描述职责与决策，接口以代码为准。Markdown 使用仓库相对链接，路径由 `make lint` 校验；远程链接可用性与标题锚点仍需人工核对。
