# ArchiveFeature

## 职责

将指定目录转换为过滤元数据的 ZIP，保留源文件并保护目标位置；管理本机打包规则、文件书签和成功历史。

## 现状

提供普通文件/开发项目两种持久化预设，扫描、准备、压缩、核对、保存阶段反馈，准备与保存显示真实字节进度。分块复制支持取消，整项任务限时 300 秒。压缩阶段不估算百分比。

书签和最近 20 条成功记录保存在本机 Application Support 的 `Kaiwu/ArchiveLibrary.json`，不参与云同步。再次打包会重新选择输出位置。设置可关闭后续记录或清除记录与书签；这些操作不删除源文件和 ZIP。

容量检查为暂存副本、压缩文件和目标旁临时文件保守预留空间。复制前后与压缩后核对文件标识、大小和修改信息，发现变化则拒绝发布。这不是文件系统原子快照；阻塞的系统 I/O 只能在调用返回后响应取消。保存使用同卷排他重命名，拒绝覆盖竞争创建的目标。

## 已完成

- [ZIP 服务](Services/ZipArchiveService.swift) 与 [分块文件读写](Services/ArchiveFileIO.swift)：元数据过滤、符号链接跳过、取消、时限、容量检查、源文件变化检测和目标保护。
- [进度与预设](Models/ArchiveProgress.swift)、[页面](Views/ArchiveView.swift)：阶段反馈、规则记忆和取消状态。
- [本机记录服务](Services/ArchiveLibraryService.swift)：目录书签、失效提示、移动后定位、成功历史、有界保留和明确的损坏数据错误。
- [规则](Models/ArchivePolicy.swift) 保留普通隐藏文件；开发预设额外排除常见依赖和构建目录。

## 下一步

完成文件面板、多窗口、设置联动和重新启动后的 UI 验收；补充真实满盘、外部卷及极大目录的设备验证。当前使用非沙盒开发包的普通文件书签；若启用 App Sandbox，需切换为 security-scoped bookmark 并验证访问生命周期。

## 验证

[基础归档测试](../../Tests/ArchiveFeatureTests/ArchiveTests.swift)、[可靠性测试](../../Tests/ArchiveFeatureTests/ArchiveReliabilityTests.swift) 使用真实 zip/unzip，覆盖 2,049 文件目录、字节进度、分块取消、保存时取消、注入容量不足、超时、源文件变化、链接替换、权限/时间保留与目标竞争保护。

[记录测试](../../Tests/ArchiveFeatureTests/ArchiveLibraryTests.swift) 使用临时数据验证持久化、保留上限、目录重命名、损坏/失效与清除边界。运行 `make check`；真实验证范围见 [验证记录](../../../../docs/VALIDATION.md)。
