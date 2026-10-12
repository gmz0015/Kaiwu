# KaiwuUI

## 职责

提供功能注册协议、公共布局和小范围 AppKit 桥接，不承担业务规则。

## 现状

FeatureModule 提供导航描述与视图工厂；面板与共享任务控件不持有业务状态。

## 已完成

[注册协议](FeatureModule.swift)、[页面容器](FeaturePage.swift)、[目录/ZIP/文本文件面板](FilePanels.swift) 与 [取消控件](ToolTaskControls.swift)。

## 下一步

完成本轮文件面板和取消控件的原生交互验收；后续按多个消费者的实际需要抽取公共布局。

## 验证

`make check` 验证编译；布局/面板变更按 [验证矩阵](../../../../docs/TESTING.md) 做交互检查，本轮工具连接限制见 [验证记录](../../../../docs/VALIDATION.md)。
