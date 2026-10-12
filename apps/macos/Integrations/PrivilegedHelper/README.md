# 提权助手预留

这里只预留接入说明，不是已注册的 root 服务。当前 Swift 接口位于 `NetworkFeature/Services/PrivilegedRepairService.swift`。

未来使用独立签名的 ServiceManagement helper target / XPC 接口；安装与授权由系统机制处理。必须验证调用方、限制动作、校验前置状态并提供结果审计与回滚。不能将 `ProcessRunner` 或任意命令字符串暴露给特权进程。

实现流程见 [网络恢复设计](../../../../docs/NETWORK-RECOVERY.md)。
