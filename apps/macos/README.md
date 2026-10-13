# 开物 Kaiwu · macOS

本目录包含完整的 macOS 应用工程。SwiftPM 管理模块与测试；Xcode App target 使用同一套模块和 App 源文件。无需下载第三方依赖即可构建基础能力。

## 开发入口

从仓库根目录运行 `make run`、`make build`、`make check` 或 `make check-all`；也可在本目录调用 `./script/build_and_run.sh`、`./script/check.sh --all`。根目录的 Codex Run 与 CI 转发到这些平台脚本。

打开 [Kaiwu.xcodeproj](Kaiwu.xcodeproj) 可进行原生调试、签名及 Capabilities 配置。App scheme 暂无测试 bundle，离线测试由 SwiftPM 执行。

构建缓存放在本目录 `.build/`，开发包为 `dist/Kaiwu.app`。本地脚本只生成 ad-hoc 签名包；正式分发请遵循 [发布流程](../../docs/RELEASING.md)。

## 模块与状态

| 模块 | 职责与当前实现 |
| --- | --- |
| 应用外壳 | [场景、组合根和导航](Sources/KaiwuApp/README.md) |
| 基础能力 | [Core](Sources/KaiwuCore/README.md)、[UI](Sources/KaiwuUI/README.md) |
| 目录打包 | [归档策略与 ZIP](Sources/ArchiveFeature/README.md) |
| 网络工具 | [诊断与恢复边界](Sources/NetworkFeature/README.md) |
| 终端 | [Ghostty 适配](Sources/TerminalFeature/README.md) |
| 代理 | [Mihomo 控制器](Sources/ProxyFeature/README.md) |
| CloudKit | [云账户与同步契约](Sources/CloudServices/README.md) |
| 工程检查 | [RepositoryChecks](Tools/RepositoryChecks/README.md) |

模块 README 维护现状、已完成、下一步和验证，避免多处复制进度。新增功能步骤见 [架构](../../docs/ARCHITECTURE.md)。默认 CloudKit 关闭；网络诊断由用户主动运行，外部探测可关闭，具体请求范围见 [NetworkFeature](Sources/NetworkFeature/README.md)。

## 打包行为

打包预设、过滤规则、目标保护、进度、书签和历史统一见 [ArchiveFeature](Sources/ArchiveFeature/README.md)。

## 配置与权限

[App.xcconfig](Configuration/App.xcconfig) 是名称、版本、Bundle ID、最低系统版本的权威来源。显示名为「开物 Kaiwu」，产品与可执行文件名为 Kaiwu；界面从应用包读取名称。

`Configuration/Local.xcconfig` 仅存本机签名覆盖，禁止提交。当前按站外分发设计，未启用 App Sandbox；正式签名、CloudKit 和系统助手参见 [基础 ADR](../../docs/decisions/0001-app-foundation.md)、[CloudKit](../../docs/CLOUDKIT.md) 与 [恢复设计](../../docs/NETWORK-RECOVERY.md)。
