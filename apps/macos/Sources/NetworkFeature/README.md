# NetworkFeature

## 职责

采集网络证据并形成修复建议，提供可预览的脱敏摘要；特权操作通过独立类型化服务边界执行。

## 现状

诊断按网络配置、DNS、连通性、代理与 PAC 分组，逐项区分通过、信息、需留意、失败、未取得结果与未运行。外部 DNS/HTTPS 探测默认开启，可在页面或设置中关闭；所有诊断都由用户主动发起。开启时通过系统解析器解析测试主机、向 `223.5.5.5` 查询 DNS，并分别通过直连和系统网络路径请求指定 HTTPS 地址。关闭时跳过上述请求，配置检查和已配置的回环端口/PAC 检查仍保留。

按服务读取系统存储的 HTTP、HTTPS、SOCKS、PAC 和自动发现设置，不修改配置。只对启用服务的回环端口建立 TCP 连接；端口可连接不代表代理转发正常。本机 PAC 仅发 HEAD 请求、不跟随重定向、不执行脚本；远端 PAC 和含凭证/查询参数的地址不请求。每轮本机端口/PAC 探测最多约 30 秒加一个正在执行的有界探测，相同目标复用结果。

导出使用白名单生成检查类型、状态和时间，经预览后保存为文本。服务名、URL、地址、路径、原始输出、错误详情和自由文本建议全部省略；它是摘要，不能替代原始诊断证据。自动修复尚未接入。

## 已完成

- [诊断服务](Services/SystemNetworkDiagnostics.swift)、[解析器](Services/NetworkParser.swift)、[HTTPS 探测](Services/SystemHTTPSProbe.swift)。
- [系统服务适配器](Services/SystemServiceProxyReader.swift)、[按服务诊断](Services/ServiceProxyDiagnostics.swift)、[本机探测](Services/LocalProxyProbe.swift)。
- [分组页面](Views/NetworkView.swift)、[脱敏摘要](Services/NetworkReportExport.swift)、[导出预览](Views/NetworkExportView.swift)。
- 外部探测选项和 HTTPS 地址与设置页共享持久化；页面任务支持取消和退出清理。

## 下一步

补充真实 VPN、多服务切换、IPv6 代理与远端 PAC 的实机验收；继续完整快照、授权 helper 与回滚设计。诊断报告不是系统配置快照，不能直接用于恢复。见 [网络恢复](../../../../docs/NETWORK-RECOVERY.md)。

## 验证

[网络测试](../../Tests/NetworkFeatureTests/NetworkTests.swift)、[代理与隐私测试](../../Tests/NetworkFeatureTests/ProxyDiagnosticsTests.swift) 使用构造配置验证失败、停用、无效字段、远端跳过、去重、关闭外部探测与脱敏白名单。

[回环集成测试](../../Tests/NetworkFeatureTests/LocalProxyIntegrationTests.swift) 绑定系统分配的回环端口，验证真实 TCP 和 HEAD 请求，不访问公网。`make check` 不改变系统网络；真实系统读取及 UI 验收范围见 [验证记录](../../../../docs/VALIDATION.md)。
