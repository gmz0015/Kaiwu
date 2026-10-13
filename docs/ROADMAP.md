# 开发路线图

路线图记录阶段顺序与验收里程碑；具体能力以 [模块状态索引](../apps/macos/README.md) 中的 README 为准，验证证据以 [VALIDATION](VALIDATION.md) 为准。代码合并与阶段验收分别记录。

## 1 · 打磨本地工具

2026-10-13 核对：[PR #3](https://github.com/gmz0015/Kaiwu/pull/3) 已于 2026-10-12 合并，ZIP 进度/预设/书签/历史、诊断分组/脱敏导出、按服务代理/本机端口/PAC 检查、持久化设置/统一任务状态均已进入主分支，PR 与合并后主分支 CI 均通过。功能现状见 [ArchiveFeature](../apps/macos/Sources/ArchiveFeature/README.md)、[NetworkFeature](../apps/macos/Sources/NetworkFeature/README.md) 和 [KaiwuApp](../apps/macos/Sources/KaiwuApp/README.md)。

2026-10-13 用户确认：剩余手动项目转入后续实际使用中的持续验收，不要求现在集中完成，也不作为后续开发的前置条件。下列项目保留未验收状态，使用反馈形成证据后再更新：

- [ ] ZIP 原生交互：目录/保存面板、阶段与取消反馈、书签、历史和再次打包
- [ ] 文件系统实测：真实满盘、跨卷/ExFAT；已有注入失败、10 万文件与 512 MiB 样本不能替代真实满盘和跨卷场景，更大规模按实际需求补验
- [ ] 网络原生交互与实机配置：分组、脱敏预览/保存、VPN、多服务切换、IPv6 与远端 PAC 的跳过行为
- [ ] 设置与任务联动：多窗口、重启后偏好、跨页取消与重复启动反馈

2026-10-13 验收推进：已补充 10 万文件、512 MiB 文件、IPv6 回环和真实只读网络诊断证据，并修复目录别名书签问题；原生交互、真实外部卷和配置切换仍待完成。具体结果见 [验证记录](VALIDATION.md)，手动步骤见 [验收操作单](LOCAL-TOOLS-ACCEPTANCE.md)。

## 2 · 内嵌终端

- [ ] 锁定 Ghostty commit 与可重现构建，确认渲染/PTY 边界
- [ ] C ABI + Swift/AppKit 适配器、SwiftUI host
- [ ] 中文输入法、复制粘贴、焦点、缩放、Metal 生命周期验收
- [ ] 多标签、分屏、工作目录会话

## 3 · 原生代理工作台

- [ ] Keychain Secret、代理组/规则/流量与连接的只读面板
- [ ] 订阅配置验证、节点切换、配置回滚
- [ ] 受控核心下载/签名校验、启动停止、日志与升级
- [ ] 网络状态快照、SMAppService helper、授权修复
- [ ] TUN、系统代理 ownership、退出恢复与崩溃后恢复

## 4 · 同步与发布

- [ ] SwiftData / CKSyncEngine 方案确认、本地持久化迁移
- [ ] CloudKit 用户 opt-in、冲突与离线队列、多设备验收
- [ ] 图标、可访问性、本地化、隐私说明
- [ ] 第三方许可决策、双架构包、Developer ID 签名、公证及更新方案
