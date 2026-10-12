# 工作流与目录责任

本表用于拆分任务和评估改动范围，不要求启动并行 agent，不指定不存在的负责人。

| 工作流 | 主要位置 | 输入 / 输出边界 | 完成条件 |
| --- | --- | --- | --- |
| 基础设施 | Core、UI、Tools、Configuration、script、Package、Xcode 工程 | 可复用能力与开发入口 | 规则、离线测试、双构建入口一致 |
| 应用体验 | KaiwuApp | 装配模块，场景和导航 | 注册、窗口与设置可用 |
| 文件工具 | ArchiveFeature | 用户目录 → 归档结果 | 内容正确、目标保护、取消/错误可见 |
| 网络工具 | NetworkFeature | 参数 → 证据与修复计划 | 无副作用诊断，失败不误报正常 |
| 终端 | TerminalFeature、Integrations/Ghostty | 目录与会话 → 终端生命周期 | 目录、焦点、输入和进程路径验证 |
| 代理 | ProxyFeature、Integrations/Mihomo | 控制器 → 代理领域状态 | 凭证边界、失败语义与真实 API 验证 |
| 云同步 | CloudServices | 白名单偏好 → 账户/同步状态 | 关闭、离线、冲突、账户切换定义清晰 |
| 系统助手 | Integrations/PrivilegedHelper、网络修复协议 | 授权动作 → 可审计结果 | 调用方验证、前置状态、回滚与实机验证 |

任务可跨多行，应在开工时说明共享契约和调用方。只有同时存在多个工作者时才分配目录所有者，避免同时改同一文件。

Package、Xcode 工程、组合根和根文档是主要冲突面。并行时指定集成负责人，先约定接口再实现，不能为避免协作复制类型或默认值。

交接写回模块 README，跨模块选择进入 [OPEN-ITEMS](OPEN-ITEMS.md)，方案确定后写 ADR。模块不是冻结区，授权范围内可调整接口并同步调用方和测试。
