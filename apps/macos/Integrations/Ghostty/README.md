# Ghostty 集成边界

当前实现见 `Sources/TerminalFeature/Services/TerminalService.swift`。此目录用于未来固定版本记录、构建说明、C bridge 与许可证清单，不自动下载引擎。

接入内嵌终端前，先完成单 surface 原型，再处理输入法、焦点、剪贴板、进程和渲染生命周期。详见 [技术决策](../../../../docs/decisions/0002-native-engines.md)。
