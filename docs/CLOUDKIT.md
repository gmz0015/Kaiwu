# CloudKit 接入准备

默认 `AppServices.live()` 注入 `DisabledCloudAccountService`，基础运行不创建 CKContainer，不要求登录 iCloud。

已提供：

- `CloudAccountServicing` 及 `CloudKitAccountService` 真实账户适配器。
- `PreferencesSyncing` 的 fetch/save 协议。
- 带 schemaVersion 的 `SyncedPreferences` 数据模型。
- 未启用的 `apps/macos/Configuration/CloudKit.entitlements.example` 模板。

## 启用步骤

1. 在 `apps/macos/Kaiwu.xcodeproj` 确定真实 Bundle ID、开发者 Team 和签名。
2. 在 Signing & Capabilities 添加 iCloud，选择 CloudKit，创建并勾选该 Team 的容器。不要使用示例字符串注册容器。
3. 由 Xcode 将 entitlement 合入 `apps/macos/Configuration/Kaiwu.entitlements`；确认 provisioning profile 与容器一致。需要增量推送时再配置相应推送能力。
4. 将组合根替换为 `CloudKitAccountService(containerIdentifier: "实际的容器标识")`，测试可用、未登录、受限与网络错误状态。
5. 实现 `PreferencesSyncing`，选择 CKSyncEngine 或 SwiftData/Core Data 集成方案，建立本地持久化、版本迁移、冲突策略、重试与账户切换逻辑。
6. 建立用户主动开启的同步开关，以及退出账户/关闭同步后的行为；账户“可用”不等于数据已经同步。

当前白名单仅包含非敏感打包偏好。目录路径、终端历史、网络报告、订阅凭证、控制器 Secret 不进入默认同步。凭证持久化应单独设计 Keychain 服务。

验收需要真实已签名 App、开发容器和测试账户；本地单元测试仅验证关闭状态与模型编码，不声称完成了真实云端同步。

来源：[Apple：Enabling CloudKit in Your App](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app)、[CloudKit](https://developer.apple.com/documentation/cloudkit)。
