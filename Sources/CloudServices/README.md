# CloudServices

## 职责

提供账户服务和白名单偏好同步契约，不依赖界面或功能模块。

## 现状

默认关闭；已有真实 CloudKit 账户适配器，但尚无数据同步实现。

## 已完成

[账户服务](Services/CloudAccountService.swift)、[偏好模型](Models/SyncedPreferences.swift)、[同步协议](Services/PreferencesSyncing.swift)。

## 下一步

确定持久化方案，接入签名容器、用户 opt-in、冲突/离线队列与账号切换；见 [CloudKit 设计](../../docs/CLOUDKIT.md)。

## 验证

[云服务测试](../../Tests/CloudServicesTests/CloudTests.swift) 验证默认关闭和模型编码，不能证明真实云端同步。
