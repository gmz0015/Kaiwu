# TerminalFeature

## 职责

封装终端入口和生命周期，不将具体引擎类型泄漏给 App 导航。

## 现状

当前在用户选择目录中启动已安装的 Ghostty；尚无内嵌终端。

## 已完成

[终端服务](Services/TerminalService.swift)、[模块入口](TerminalModule.swift)、[页面](Views/TerminalView.swift)。

## 下一步

固定 libghostty 版本，接入 surface、PTY、焦点和输入法；见 [集成边界](../../Integrations/Ghostty/README.md)。

## 验证

`make check` 检查编译；真实 Ghostty 的目录和窗口行为、未来内嵌输入链路需要实机验收，不伪造离线端到端结论。
