# NetworkFeature

## 职责

采集网络证据并形成修复建议；特权操作通过独立类型化服务边界执行。

## 现状

已提供只读诊断；自动修复未接入，默认修复服务明确返回不可用。

## 已完成

[诊断服务](Services/SystemNetworkDiagnostics.swift)、[解析器](Services/NetworkParser.swift)、[HTTPS 探测](Services/SystemHTTPSProbe.swift)、[页面](Views/NetworkView.swift)。

## 下一步

按服务的代理/端口/PAC 检测、完整快照、授权 helper 与回滚。设计见 [网络恢复](../../docs/NETWORK-RECOVERY.md)。

## 验证

[网络测试](../../Tests/NetworkFeatureTests/NetworkTests.swift) 离线验证地址范围、解析和失败语义；真实网络探测与授权修复需另行验收。
