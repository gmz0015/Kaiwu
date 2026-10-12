# ArchiveFeature

## 职责

将指定目录转换为过滤元数据的 ZIP，保留源文件并保护目标位置。

## 现状

可选排除开发产物，跳过符号链接，支持取消；采用暂存副本，需要额外磁盘空间。

## 已完成

[模块入口](ArchiveModule.swift)、[规则](Models/ArchivePolicy.swift)、[ZIP 服务](Services/ZipArchiveService.swift)、[页面](Views/ArchiveView.swift)。

## 下一步

进度、保存规则、历史与书签；大目录、磁盘不足和源文件变化的专项验证。

## 验证

[归档测试](../../Tests/ArchiveFeatureTests/ArchiveTests.swift) 使用真实 zip/unzip，覆盖过滤、特殊路径、链接、完整性和目标保护；运行 `make check`。
