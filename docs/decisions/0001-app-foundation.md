# ADR 0001：原生模块化基础

状态：初始化采用；分发方式可在发布前调整。

## 决策

- macOS 14+、Swift 6、SwiftUI。业务和 UI 使用 Swift；允许隔离的非 Swift 原生引擎。
- SwiftPM 管理模块与测试，附带原生 Xcode App target，避免日后为签名、CloudKit 与 helper 重建工程。
- 没有第三方 Swift 依赖，基础构建可离线进行。
- 默认按 Developer ID 站外分发准备，开发期不启用 App Sandbox。真实签名与公证尚未配置。

## 理由与后果

应用包含终端、任意用户目录归档、系统诊断、可选提权修复。不同能力的授权边界需要独立处理。开发期先验证本地运行与模块边界；如需 Mac App Store，需要重新评估沙盒、文件 security-scoped bookmarks、终端子进程和系统修复能力，而不是直接启用一个布尔开关。

非沙盒也不会绕过 TCC 或系统管理员授权。文件访问仍由系统权限限制，网络修复必须通过签名 helper 的受控动作进行。

## 签名待办

1. 确认最终 Bundle ID 与 Apple Developer Team。
2. 正式产品标识与版本在 `Configuration/App.xcconfig` 修改。本地 `Configuration/Local.xcconfig` 仅覆盖 `DEVELOPMENT_TEAM`、`CODE_SIGN_IDENTITY` 等签名设置，文件已被忽略。
3. Xcode 配置 iCloud / helper 等所需 capability；开发打包脚本从 App.xcconfig 读取标识。
4. 为独立引擎、XPC/helper 完成嵌套签名和 hardened runtime 验证。
5. 归档、Developer ID 签名、公证、staple，另行建立发布工作流。

参考：[Apple App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)、[SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)。
