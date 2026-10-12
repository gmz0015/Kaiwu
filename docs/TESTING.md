# 测试与验证

## 按变更选择检查

| 变更 | 最少检查 | 额外证据 |
| --- | --- | --- |
| 文档、模板、仅注释 | `make lint` | 文档准确性与链接目标人工审阅 |
| Swift 行为、模型、协议、源文件移动 | `make check` | 行为测试；UI 变化增加手动验证 |
| Package、工程、plist、xcconfig、脚本、CI | `make check-all` | 打包脚本变化另跑 `make build`，检查包元数据 |
| 外部引擎、系统网络、CloudKit | 上述相关检查 | 真实服务/设备验收，明确授权和恢复方式 |

macOS 命令由 `apps/macos/script/` 定义，根 script、Makefile 和 CI 调用同一入口。`make lint` 会编译轻量 Swift 检查器，不运行应用或业务测试。测试数据写入临时目录，构建缓存写入 `apps/macos/.build/`，开发包写入 `apps/macos/dist/`。

swift-format 随当前 `xcode-select` 指向的工具链运行。CI 会输出工具链版本；若本地与 CI 的格式结果不同，应先对齐工具链并核实差异，不能屏蔽 lint。远端 CI 结果以对应提交的 checks 为准；最低工具链组合仍需单独验证。

## 测试层次

- 纯规则：地址解析、策略、配置验证、模型编码与错误语义。
- 本地集成：真实 zip/unzip、子进程退出、取消、超时和输出；数据由测试临时创建。代理探测测试仅绑定系统分配的回环端口，不访问公网或真实代理。
- UI：导航、选择目录、反馈、取消、窗口与设置；进程存在不代替交互验收。
- 外部集成：Ghostty、受控 Mihomo 控制器、已签名 CloudKit、特权 helper；离线 mock 通过不代表真实系统可用。

新增行为按风险覆盖正常、边界和失败路径。安全、数据丢失和并发边界优先；低影响文案、样板和目录说明不强制新建测试。无性能证据时不要宣称性能提升。

## 仓库规则检查范围

`apps/macos/Tools/RepositoryChecks` 读取 SwiftPM 实际 manifest，检查层级依赖、本地模块直接 import、模块 README、局部 Markdown 路径、文本换行和应用元数据一致性。检查器有反例测试，确保错误依赖和失效链接被拒绝。

检查器将 manifest 内的目标路径解析到 `apps/macos/`，避免迁移后漏检 import；Markdown 和文本格式检查仍遍历整个仓库，包括 `docs/`、`changelog/`。其他平台需增加对应构建与检查，不能认为根入口会自动覆盖未来平台。

它不替代完整 Swift 语法分析、远程链接检查、凭证扫描或运行时权限审计。新增 import 语法需同步检查器；`@unchecked Sendable`、`try?` 的合理性由审阅确认。

## 结果记录

交付写出命令、结果、环境和未验证范围。长期能力声明追加到 [VALIDATION](VALIDATION.md)，不覆盖旧记录。CI 工作流存在与远端 CI 成功是两件事，只有真实运行过才能记录通过。

全绿后仅在后续修改、失败或具体疑点出现时重跑。不得以降低规则、隐藏失败或删除断言替代修复。
