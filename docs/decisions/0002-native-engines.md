# ADR 0002：Ghostty 与 Mihomo 的接入方式

核查日期：2026-10-12。引擎引入时应固定版本/commit、校验下载和审阅变更。

## Ghostty

采用两阶段接入：

1. 当前通过 `TerminalServicing` 适配已安装的 Ghostty，以指定工作目录打开独立应用。
2. 后续建立 `GhosttyAdapter`，封装 C ABI、渲染 surface、PTY、键盘/输入法、窗口焦点、剪贴板、生命周期，再以小型 `NSViewRepresentable` 暴露给 SwiftUI。

上游提供 C/Zig 的 `libghostty`；其 README 说明 `libghostty-vt` 已可使用，但 API 仍在变化，尚未正式打版本。VT 状态库和完整可交互渲染终端的集成范围应分别评估，不能假定它等价于一个现成 SwiftUI 控件。初始化不固定未经验证的 binary URL 或拉取整份上游源码。

Ghostty 为 MIT 许可；真正分发引擎时保留上游版权和许可声明，并核查相关依赖。

来源：[Ghostty README](https://github.com/ghostty-org/ghostty)、[Ghostty LICENSE](https://github.com/ghostty-org/ghostty/blob/main/LICENSE)、[libghostty C API](https://libghostty.tip.ghostty.org/)。

## Clash 类能力

可行，建议构建自己的 SwiftUI 客户端，使用 Mihomo 核心完成协议与规则执行。Clash Verge Rev 本身采用 Tauri/Rust 并内置 Mihomo，不适合直接当作 SwiftUI 组件嵌入。

建议模块继续拆分为：

- `ProxyControlling`：版本、配置、节点、规则、连接与流量 API。
- `CoreManaging`（后续）：核心校验、启动停止、日志、崩溃与升级。
- `ProfileRepository`（后续）：订阅、配置验证、版本与回滚。
- `SystemProxyServicing`（后续）：只管理当前应用启用的系统代理，保存原配置。
- `PrivilegedRepairServicing`：TUN 与网络恢复的授权边界。

首版仅实现手动连接 loopback 控制器并读取 `/version`。Secret 仅使用 Authorization header，拒绝远端地址、用户信息、查询参数、控制字符和重定向。UI 展示的端口 9090 是可修改的示例，不能据此判断用户现有应用的真实配置。

后续优先级：只读监控 → 节点/规则控制 → 本应用托管核心 → 系统代理 → TUN。不要在初始化阶段启动第二个核心、接管用户现有代理或导入订阅。

Clash Verge Rev 与 Mihomo 上游均使用 GPL-3.0 许可。只参考产品功能和直接复制/修改源代码、打包分发核心是不同的选择；独立进程并不自动消除许可义务。本项目沿用远端初始化时的 MIT 许可证；正式引入引擎前仍需审查第三方许可要求及源码/声明的交付方式，本工程尚未复制或打包其代码。这里记录工程约束，不对具体分发方案作法律结论。

来源：[Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev)、[Mihomo LICENSE](https://github.com/MetaCubeX/mihomo/blob/Meta/LICENSE)、[Mihomo API](https://wiki.metacubex.one/api/)。
