# 验证记录

## 2026-10-12 · 初始工程

日期：2026-10-12。

| 检查 | 结果 |
| --- | --- |
| SwiftPM Debug 构建 | 通过 |
| Swift Testing | 19 项通过 |
| 原生 Xcode App Debug 构建（arm64） | 通过 |
| Info.plist / entitlements / pbxproj 语法 | 通过 |
| 构建与检查脚本语法 | 通过 |
| `build_and_run.sh --verify` | .app 已生成、启动，进程存在 |
| 原生 UI 观察 | 已读取侧边栏与终端页面，检查窗口截图 |

工具链：Xcode 27.0、Swift 6.4。未在 macOS 14 或 Intel 真机上运行；最低版本与架构兼容性仍需要 CI/设备覆盖。Xcode 输出本机 CoreDevice / CoreSimulator 组件版本警告，但本次 macOS App 构建退出码为 0。

测试覆盖：ZIP 嵌套过滤、保留普通隐藏文件、中文/空格/特殊文件名、符号链接跳过、ZIP 完整性、源文件不变、目标保护与空目录；子进程参数、取消、超时与大输出；完整 Fake IP 地址段、TUN 解析、诊断失败语义；控制器 endpoint 和 Secret 验证；CloudKit 默认关闭与模型编码。

未执行系统修复，未连接真实 CloudKit 容器，未在测试中访问真实 Mihomo 控制器。公网网络诊断需由用户主动运行；内嵌引擎、签名 helper 与同步尚未实现。

本地可重跑（命令随当前工程名同步）：

```bash
./script/check.sh
./script/build_and_run.sh --verify
xcodebuild -project apps/macos/Kaiwu.xcodeproj -scheme Kaiwu \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath apps/macos/.build/xcode CODE_SIGNING_ALLOWED=NO build
```

CI 工作流已创建，但尚未推送到远端执行。

## 2026-10-12 · 项目结构与开发纪律

本次整理模块目录，建立 AGENTS/CONTRIBUTING、模块交接文档、仓库规则检查器和统一开发入口。未增加业务能力，未对参考项目做修改。

| 检查 | 实际结果 |
| --- | --- |
| `./script/check.sh --all` | 退出码 0；格式、依赖、文档、配置、SwiftPM、Xcode Debug 全部通过 |
| Swift Testing | 25 项通过，其中 6 项验证仓库规则的正常与拒绝路径 |
| `make build` | 成功生成开发 `.app`，未重启应用 |
| `codesign --verify --strict`（当时的开发包） | 退出码 0 |
| SwiftPM / Xcode 包元数据 | 名称、Bundle ID、版本、构建号与最低系统版本一致，无未展开变量 |
| 应用包内容 | 两种构建产物均未包含模块 README |
| `CLAUDE.md` | 符号链接目标为 `AGENTS.md` |

环境仍为 Xcode 27.0 / Swift 6.4 / arm64；远端 CI、旧系统、Intel、外部服务和 UI 交互未在本次重新验收。本机 Xcode 的设备组件版本警告不影响本次 macOS 构建结果。现有初始化文件及本次改动均未提交或推送。

## 2026-10-12 · 开物 Kaiwu 命名统一

品牌与显示名统一为「开物 Kaiwu」，工程、scheme、可执行产品及基础模块统一使用 Kaiwu 前缀，开发 Bundle ID 调整为 `dev.kaiwu.app`。App.xcconfig 分别定义产品名和显示名，窗口、导航、设置与系统菜单使用包内元数据。

| 检查 | 实际结果 |
| --- | --- |
| `./script/check.sh --all` 的静态检查、SwiftPM 构建与测试阶段 | 通过，25 项测试通过 |
| 原生 Xcode Debug 构建 | 首次被沙盒限制 SwiftPM 缓存写入；允许缓存访问后以相同工程、scheme 和构建参数重跑，退出码 0 |
| `make build` | 生成 `dist/Kaiwu.app` |
| `codesign --verify --strict dist/Kaiwu.app` | 退出码 0 |
| SwiftPM / Xcode 包元数据 | 显示名均为「开物 Kaiwu」，可执行文件均为 Kaiwu；Bundle ID、版本、构建号和最低系统版本一致，无未展开变量 |
| `./script/build_and_run.sh --verify` | 构建、启动成功，Kaiwu 进程存在 |
| 原生 UI 观察 | 应用及菜单显示「开物 Kaiwu」，设置页“应用”字段显示「开物 Kaiwu」 |
| 旧名称扫描 | 当前源码、工程、配置、脚本及文档无旧名称引用；不包含历史构建缓存与产物 |

本次沿用既有工作区路径，没有迁移工作区目录。环境仍为 Xcode 27.0 / Swift 6.4 / arm64；未验证远端 CI、旧系统、Intel、正式签名和外部服务。未提交或推送。

## 2026-10-12 · 按平台整理工程目录

完整 macOS 工程迁入 `apps/macos/`，根目录保留文档、开发纪律及兼容命令入口，新增平台目录说明与 changelog。业务 Swift 源码、Package manifest、Xcode 工程内部引用和应用权限配置保持原内容。

| 检查 | 实际结果 |
| --- | --- |
| 根 `./script/check.sh --all` | 退出码 0；迁移后的 SwiftPM 与原生 Xcode Debug 构建通过 |
| 路径修复后的根 `make check` | 退出码 0；27 项测试通过，包括嵌套目标路径、真实目录别名与越界拒绝用例 |
| 仓库检查器反例 | 在临时仓库中注入非法 import 与 changelog 失效链接，均按预期拒绝；反例已清理 |
| 从仓库外调用 `script/build_and_run.sh --build-only` | 退出码 0，生成 `apps/macos/dist/Kaiwu.app` |
| 开发包签名与元数据 | codesign 严格验证通过；与 Xcode 包的名称、标识、版本和最低系统版本一致；未混入模块 README |
| 文件迁移核对 | 所有业务 Swift 源码内容保持一致，变更集中在开发入口、路径检查和文档 |
| 忽略规则 | 平台 Local.xcconfig、缓存与产物均被忽略 |
| Gitleaks 8.30.1 工作树候选文件扫描 | 0 发现；只扫描准备纳入版本控制的文本文件，未上传源码 |

反例验证发现 Foundation 在枚举时可能保留系统目录的 /private 前缀；已对根路径与文件路径统一归一化，避免静默跳过 import 检查。检查器修复后重新运行静态检查、SwiftPM 构建和全部测试，未重复无关的 UI 验收。

本次使用 Xcode 27.0 / Swift 6.4 / arm64，在独立 worktree 完成。未提交或推送，未重新运行远端 CI、旧系统、Intel 或外部服务验收。
