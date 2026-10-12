# KaiwuApp

## 职责

装配服务与功能模块，提供原生场景、导航和设置，不实现打包或网络业务。

## 现状

使用 WindowGroup 与独立 Settings；由组合根注入服务。窗口、导航和设置通过 AppIdentity 读取应用包中的「开物 Kaiwu」显示名。

## 已完成

[组合根](App/AppServices.swift)、[应用入口](App/KaiwuApp.swift)、[应用标识](App/AppIdentity.swift)、[导航](Navigation/ContentView.swift)。

## 下一步

菜单栏入口、统一任务生命周期、可访问性与本地化。

## 验证

`make check-all`；UI 变化需手动检查导航、窗口、设置。当前 App scheme 不含 UI 自动化测试。
