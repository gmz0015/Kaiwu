# ADR 0004：按平台组织客户端工程

- 日期：2026-10-12
- 状态：采用
- 背景：macOS 工程原先占用仓库根目录，需要为后续平台保留独立位置。

## 决策

平台工程统一放在 `apps/<platform>/`，macOS 的源码、测试、SwiftPM/Xcode 工程、配置、集成、工具与脚本迁入 `apps/macos/`。根目录保留治理文件、docs、changelog、CI、Makefile 和兼容命令入口。

根脚本只转发参数和退出码，macOS 逻辑只在平台脚本中实现。Codex Run 和 CI 继续使用根入口，SwiftPM 与 Xcode 从同一个平台目录解析相对路径。平台缓存、开发包分别位于自身 `.build/` 与 `dist/`。

仓库检查器将 manifest 的源文件、测试、工具路径解析到平台目录，同时继续遍历整个仓库检查文档与文本。新增平台独立提供对应工具链和 CI job，不自动套用 macOS 检查器的模块规则。

## 取舍

- 不预建尚无实现的其他平台工程或共享模块；未来出现真实消费者时再提取共享包。
- docs 保留架构、流程与历史证据；changelog 记录未发布与版本变化，模块 README 仍负责当前实现状态。
- 保留根开发命令的兼容性；直接调用 SwiftPM 时需指定 `--package-path apps/macos`，直接打开 Xcode 时使用新路径。

## 验证

运行根 `make check-all` 和开发包构建，核对新路径下的元数据及签名；回归用例覆盖嵌套 package 的普通目标、测试与显式工具路径。实际结果见 [验证记录](../VALIDATION.md)。
