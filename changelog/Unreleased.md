# 未发布

以下内容尚未正式发布，不代表全部规划功能已经实现。

## 新增

- [macOS] 建立开物 Kaiwu 的 Swift / SwiftUI 模块化工程及 SwiftPM、Xcode 构建入口。
- [macOS] 提供目录 ZIP 打包、只读网络诊断、外部 Ghostty 启动与本机 Mihomo 版本查询，预留云同步和授权修复边界。
- [仓库] 建立开发规范、离线测试、CI 和公开仓库提交审查流程。
- [仓库] 新增 changelog 目录，用于维护未发布变更和后续版本记录。

## 调整

- [仓库] macOS 源码、测试、工程、配置、集成和平台脚本统一迁入 `apps/macos/`，为后续平台保留独立目录空间。
- [macOS] 保留仓库根目录 make、script 和 Codex Run 入口；开发包改为 `apps/macos/dist/Kaiwu.app`，构建缓存改为 `apps/macos/.build/`。
- [仓库] 更新文档链接与目录约定；平台检查继续覆盖根目录文档和变更记录。

## 修复

- [仓库] 统一检查器的根路径与文件枚举路径，避免通过系统目录别名访问仓库时漏检模块 import。
