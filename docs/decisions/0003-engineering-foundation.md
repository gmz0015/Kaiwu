# ADR 0003：开发规范与可执行检查

- 日期：2026-10-12
- 状态：采用
- 背景：需要完善项目结构、规范和开发纪律。

## 决策

采用五条工程原则：单一权威来源、闭合职责边界、在故障源修复、优先结构性收敛、以证据支持结论。CONTRIBUTING 定义原则，AGENTS 负责入口，模块 README 负责交接。

功能按入口、Models、Services、Views 组织，不为空能力建 target。使用工具链内置 swift-format 和纯 Swift 的仓库检查器，本地与 CI 调用同一入口。

元数据集中到 App.xcconfig，SwiftPM 平台声明通过一致性检查约束。模块入口与视图分离，导航层保持组合职责。

## 适配与取舍

- 不移植 TypeScript、pnpm、changesets 或宿主特定规则。
- 无冻结接口或预先分配的 agent，不增加普通跨模块改动的审批。
- 已有 HEAD 后采用任务分支/worktree；当前初始化例外不授权自动建立基线提交。
- 使用用户既有的中文 Conventional Commits，而非参考仓库的方括号包名前缀。
- 不伪造 CODEOWNERS，不声称未创建的远端已启用保护或发布。
- 规则检查不替代编译器、运行时验证或完整安全审计。

## 验证

执行 `make check-all`；用失败样例验证跨功能依赖、未声明依赖和失效链接会被拒绝。真实结果见 [VALIDATION](../VALIDATION.md)。
