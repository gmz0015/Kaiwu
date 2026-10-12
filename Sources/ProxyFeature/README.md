# ProxyFeature

## 职责

将本机控制器接口转换为代理领域状态，不擅自托管核心或接管系统代理。

## 现状

仅主动读取 loopback Mihomo 版本；Secret 留在页面内存，退出清空。

## 已完成

[控制器适配器](Services/ProxyController.swift) 校验地址/凭证并拒绝重定向；[页面](Views/ProxyView.swift) 展示连接结果。

## 下一步

凭证存储、只读监控、订阅与节点、核心管理和系统代理 ownership；见 [Mihomo 边界](../../Integrations/Mihomo/README.md)。

## 验证

[控制器测试](../../Tests/ProxyFeatureTests/ProxyTests.swift) 覆盖请求、Secret 和 endpoint；真实控制器联调单独记录。
