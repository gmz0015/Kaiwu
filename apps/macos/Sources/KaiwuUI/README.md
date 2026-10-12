# KaiwuUI

## 职责

提供功能注册协议、公共布局和小范围 AppKit 桥接，不承担业务规则。

## 现状

FeatureModule 负责导航所需的描述与视图工厂，面板不持有页面状态。

## 已完成

[注册协议](FeatureModule.swift)、[页面容器](FeaturePage.swift)、[文件面板](FilePanels.swift)。

## 下一步

按多处实际使用需求抽取反馈、任务展示等控件；不要预建大组件库。

## 验证

`make check` 验证编译；布局/面板变更按 [验证矩阵](../../../../docs/TESTING.md) 做交互检查。
