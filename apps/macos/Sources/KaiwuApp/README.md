# KaiwuApp

## 职责

装配服务与功能模块，提供原生场景、导航和设置，不实现打包或网络业务。

## 现状

使用 WindowGroup、独立 Settings 与 MenuBarExtra；组合根共享本机打包记录服务。设置提供默认打包规则、历史开关和清除、探测地址、外部探测选项以及控制器地址；Secret 不持久化。窗口、导航和设置通过 AppIdentity 读取包内显示名。应用使用自定义图标；菜单栏提供打开主窗口、设置及退出，关闭窗口后仍保留入口，Dock 行为保持普通应用。

## 已完成

[组合根](App/AppServices.swift)、[应用入口](App/KaiwuApp.swift)、[应用标识](App/AppIdentity.swift)、[导航](Navigation/ContentView.swift) 与 [持久化设置](Settings/SettingsView.swift)。

[菜单栏入口](MenuBar/MenuBarContentView.swift)、浅色/深色模板图标与全尺寸应用图标；资源来源和再生成方式见 [图标原图](../../Resources/IconSources/README.md)。

## 下一步

补充设置与工具页面联动、多窗口和重新启动后的原生验收；后续完善可访问性与本地化。

## 验证

`make check-all`；UI 变化需手动检查导航、窗口、设置。当前 App scheme 不含 UI 自动化测试。本轮实际验证与工具限制见 [验证记录](../../../../docs/VALIDATION.md)。
