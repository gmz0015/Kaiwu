# 架构与扩展

## 分层依赖

```mermaid
flowchart TD
    App[KaiwuApp · 组合根与场景] --> Features[Archive / Network / Terminal / Proxy]
    App --> Cloud[CloudServices]
    Features --> UI[KaiwuUI]
    Features --> Core[KaiwuCore]
    UI --> Core
```

功能模块不互相 import。跨功能的数据交流后续通过 Core 中明确的协议和值类型完成；禁止把 Shell、CloudKit、代理核心实现直接放进 App 导航层。

- **App 层**：`AppServices.live()` 是唯一默认依赖装配入口，场景提供 `WindowGroup` 与独立 `Settings`。
- **Core 层**：只包含可复用模型与基础服务，不 import SwiftUI。
- **UI 层**：`FeatureModule` 暴露稳定 ID、描述与视图工厂，`AnyView` 只用于功能模块边界。
- **Feature 层**：一个功能一个 target，内部按服务、模型和界面拆文件，协议支持测试替身。
- **CloudServices**：独立于具体页面，当前只提供账户适配器、同步契约和白名单模型。

没有动态下载插件或运行用户脚本的机制。这里的“可扩展”是编译期模块注册，减少初始化阶段的复杂度。

## 状态所有权

| 状态 | 所有者 |
| --- | --- |
| 依赖实例 | App 的组合根 |
| 窗口导航 | `@SceneStorage`，每个窗口独立 |
| 表单、结果、任务 | 功能页面的 `@State` |
| 可持久化探测地址 | `@AppStorage` |
| 控制器 Secret | 页面内存；离开页面清空，后续持久化使用 Keychain |
| 文件处理 | actor 服务，不阻塞主线程 |

较复杂功能可以引入 `@MainActor @Observable` store；不为简单表单添加多余 ViewModel。离开 ZIP/诊断页面会取消相应任务，首版不提供后台任务队列。

## 新增功能步骤

1. 创建 `Sources/YourFeature/`，按需求添加模型、服务协议、实现与视图。
2. 在 `Package.swift` 增加 target 和 library product，通常依赖 Core / UI。
3. 实现 `FeatureModule`，保证 `descriptor.id` 唯一且发布后稳定。
4. 为 App executable 增加依赖；在 Xcode App target 的 Frameworks, Libraries, and Embedded Content 中加入对应本地 package product。
5. 在 `AppServices.live()` 中注入服务并注册模块；侧边栏与工作台自动显示。
6. 添加模块 README，按模板维护职责、现状、已完成、下一步和验证；在 Package target 中排除 README。
7. 为有行为的服务补充 `Tests/YourFeatureTests`，直接声明测试所 import 的每个本地模块。运行 `make check-all`。

功能模块根目录只保留 `*Module.swift` 入口和 README，具体实现分入 `Models`、`Services`、`Views`。小模块不强制建立未使用的目录。开发工具单独放在 `Tools`，不链接进 App。

边界规则由 `Tools/RepositoryChecks` 检查；实际依赖以 Package.swift 为准。共同代码格式、状态交接与工作区纪律见 [开发规范](../CONTRIBUTING.md)。

## 系统边界

`ProcessRunner` 使用绝对可执行文件路径与参数数组，无 `/bin/sh -c`。它在后台运行子进程，支持取消、超时、终止升级和限量读取输出。临时文件避免 stdout/stderr 管道阻塞。环境变量不继承用户的代理、ZIP 参数或 shell 配置。该服务只用于受控系统工具，不是用户可配置的命令执行平台。

AppKit 仅用于系统文件对话框、应用启动和 Finder 定位；主界面和状态由 SwiftUI 管理。

修复助手目前只有 `PrivilegedRepairServicing` 和类型化 `RepairAction` 接口，默认实现明确返回不可用。禁止通过拼接 sudo / AppleScript 命令绕开这个边界。

## 当前验证边界

自动测试不访问公网、不修改系统网络，不需要 Ghostty/Mihomo/CloudKit 账户。ZIP 测试运行真实系统 zip/unzip，进程测试验证参数、超时、取消和大输出；网络和控制器测试使用解析样例与构造请求。实际外部应用启动、Mihomo API 连接和已签名 CloudKit 需接入后进行集成验收。
