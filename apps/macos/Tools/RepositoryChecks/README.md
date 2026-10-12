# RepositoryChecks

## 职责

将可自动验证的目录、依赖、文档与元数据纪律落实为离线命令，不承担业务测试。

## 现状

纯 Swift 可执行工具，由 macOS 的 `script/lint.sh` 传入仓库根路径及实际 SwiftPM manifest；将模块路径解析到 `apps/macos/`，文档和文本检查覆盖整个仓库，不依赖第三方包。

## 已完成

- 层级依赖和本仓库模块的直接 import 检查。
- 模块 README 必备小节与 Package 排除项检查。
- Markdown 本地路径和文本换行检查，覆盖尚未被 Git 跟踪的文件。
- App.xcconfig、Package 平台与 Info.plist 引用的一致性检查。
- 嵌套平台目标路径解析，统一目录别名，避免文件枚举路径差异导致 import 漏检。

## 下一步

新建模块层级或采用新的 import 语法时，扩展规则和反例测试。远程链接、完整 Swift 解析、权限和秘密检测不在当前检查范围。

## 验证

[规则测试](../../Tests/RepositoryChecksTests/RepositoryRulesTests.swift) 验证非法依赖、传递导入、失效链接、文本格式与错误输入。运行 `make check`。
