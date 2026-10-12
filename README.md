# 开物 Kaiwu

面向开发与日常办公的原生 macOS 工具箱。应用代码使用 **Swift 6 + SwiftUI**，最低支持 **macOS 14**，允许通过独立适配器接入 Ghostty / Mihomo 等原生引擎。

当前是可运行、可测试的工程起点，不是全部功能已经完成的发行版本。基础构建不需要下载第三方依赖，不需要开发者账户。

开发前先读 [AGENTS.md](AGENTS.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md)。完整入口见 [文档地图](docs/README.md)。

## 开始开发

要求：macOS 14+、Xcode 16+（含 Swift 6），`xcode-select` 指向完整 Xcode。初始化时使用 Xcode 27 / Swift 6.4 验证；最低工具链兼容性由后续 CI 持续验证。

```bash
./script/build_and_run.sh          # 构建 .app 并启动；Codex Run 使用同一入口
./script/build_and_run.sh --verify # 启动并检查进程
make lint                         # 格式、依赖、模块文档、链接与配置检查
make check                        # 静态检查、SwiftPM 构建与离线测试
make check-all                    # 再验证原生 Xcode 工程
open apps/macos/Kaiwu.xcodeproj     # 原生 App target：调试、签名、Capabilities
```

`--build-only` 生成 `apps/macos/dist/Kaiwu.app`；另支持 `--debug`、`--logs`、`--telemetry`。本地脚本生成 ad-hoc 签名的开发包，正式签名、公证和 CloudKit 请使用 Xcode 工程。不要直接用 SwiftPM 可执行文件启动 GUI，以免缺少应用包元数据。

SwiftPM 是模块与测试入口；Xcode App target 引用同一套本地 Package 模块和 App 源文件。测试统一通过 `swift test --package-path apps/macos` / `script/check.sh` 执行，App scheme 的 Test action 暂不绑定测试 bundle。上述命令均从仓库根目录运行。

## 功能与状态入口

| 模块 | 职责与当前实现 |
| --- | --- |
| 应用外壳 | [场景、组合根和导航](apps/macos/Sources/KaiwuApp/README.md) |
| 基础能力 | [Core](apps/macos/Sources/KaiwuCore/README.md)、[UI](apps/macos/Sources/KaiwuUI/README.md) |
| 目录打包 | [归档策略与 ZIP](apps/macos/Sources/ArchiveFeature/README.md) |
| 网络工具 | [诊断与恢复边界](apps/macos/Sources/NetworkFeature/README.md) |
| 终端 | [Ghostty 适配](apps/macos/Sources/TerminalFeature/README.md) |
| 代理 | [Mihomo 控制器](apps/macos/Sources/ProxyFeature/README.md) |
| CloudKit | [云账户与同步契约](apps/macos/Sources/CloudServices/README.md) |

各模块 README 维护“现状 / 已完成 / 下一步 / 验证”，此处只保留索引。

默认注入关闭的 CloudKit 服务；启动不会触发账户访问、云同步或网络探测。网络探测必须主动点击，会访问用户指定的 HTTPS 地址，并向 `223.5.5.5` 发起 DNS 对照查询。

## 目录结构

```text
apps/
  README.md                  平台目录约定与新增平台步骤
  macos/                     完整 macOS 工程
    Kaiwu.xcodeproj/          原生 App target 与共享 scheme
    Package.swift            Swift 模块依赖与测试目标
    Sources/                 App、Core、UI、功能与云服务
    Tests/                   离线及本地集成测试
    Configuration/           plist、xcconfig、entitlements
    Integrations/            原生引擎与系统助手接入说明
    Tools/                   Swift 仓库规则检查器
    script/                  macOS 构建、运行和检查实现
    .swift-format            Swift 格式规则
docs/                        架构、流程、决策与验证记录
changelog/                   未发布变更和后续版本记录
script/                      仓库入口，转发到平台脚本
.github/                     CI、PR 与 issue 模板
.codex/environments/         Codex Run 配置
AGENTS.md / CLAUDE.md        Agent 入口与符号链接
CONTRIBUTING.md              工程原则、开发纪律与完成标准
Makefile                    常用命令导航
```

平台实现与配置集中在 [macOS 工程](apps/macos/README.md)。新增平台按 [平台约定](apps/README.md) 放入 `apps/<platform>/`，不预建空工程。根脚本只转发到平台脚本，缓存与开发产物分别放在 `apps/macos/.build/` 和 `apps/macos/dist/`。

文档入口为 [docs](docs/README.md)；变更记录入口为 [changelog](changelog/README.md)，未发布内容写入 [Unreleased](changelog/Unreleased.md)。

## 打包行为

- 默认递归排除 `.DS_Store`、`._*`、`__MACOSX`、`.Spotlight-V100`、`.Trashes`、`.fseventsd`、`.TemporaryItems`。
- `.git`、`.build`、`node_modules`、`DerivedData` 由独立选项控制；其他隐藏文件（包括 `.env`）保留。分享前请自行确认目录内容。
- 跳过符号链接与非常规文件，不跟随链接读取其他目录；保留空目录。
- 目标 ZIP 必须位于源目录外，并使用未占用的文件名。先在临时目录构建，再写入目标位置；失败或取消会清理临时产物。
- 使用系统 `/usr/bin/zip`，Swift 负责遍历、策略与任务控制；不依赖 shell 拼接。需要容纳暂存副本与 ZIP 的磁盘空间，打包期间请避免修改源目录。

## 继续扩展

参见 [架构与扩展](docs/ARCHITECTURE.md)、[开发路线图](docs/ROADMAP.md)、[Ghostty / Mihomo 决策](docs/decisions/0002-native-engines.md)、[CloudKit 配置](docs/CLOUDKIT.md)。新增功能只需新建 target，实现 `FeatureModule`，并在 `AppServices.live()` 注册。

应用元数据的权威来源是 [App.xcconfig](apps/macos/Configuration/App.xcconfig)。正式发布前替换开发占位标识并配置签名；当前按站外分发设计，未启用 App Sandbox。详见 [分发与权限](docs/decisions/0001-app-foundation.md) 与 [发布流程](docs/RELEASING.md)。

品牌与界面显示名为「开物 Kaiwu」（`APP_DISPLAY_NAME`）；工程、scheme、SwiftPM 产品及可执行文件使用 `Kaiwu`（`PRODUCT_NAME`），开发 Bundle ID 为 `dev.kaiwu.app`。界面从应用包读取显示名，构建脚本和 Xcode 均从同一配置生成元数据。

公开仓库：[gmz0015/Kaiwu](https://github.com/gmz0015/Kaiwu)。项目使用远端初始化时确定的 [MIT 许可证](LICENSE)。当前未捆绑 Ghostty 或 Mihomo 核心，后续引入第三方代码与二进制需独立核查许可及分发要求。

每次提交与推送前必须完成 [公开仓库审查](docs/PUBLIC-REVIEW.md)，包括凭证、个人信息、待推送历史、提交身份与产物检查。通过任务分支和 PR 交付，正式发布按 [发布流程](docs/RELEASING.md) 执行。
