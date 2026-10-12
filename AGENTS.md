# 开物 Kaiwu：开发纪律与入口

面向开发与日常办公的原生 Mac 工具箱。应用代码采用 Swift / SwiftUI，原生引擎通过独立适配器接入。

## 必读顺序

1. 本文件：纪律摘要与导航。
2. [CONTRIBUTING.md](CONTRIBUTING.md)：工程原则和流程的权威定义。
3. [架构](docs/ARCHITECTURE.md)：模块边界与状态所有权。
4. 本次涉及模块的 README：职责、现状、已完成、下一步和验证。
5. [待定事项](docs/OPEN-ITEMS.md)：只看是否影响当前工作。

完整文档地图见 [docs/README.md](docs/README.md)。`CLAUDE.md` 链接到本文件，不另维护一份纪律。

## 执行纪律

- 同一事实只有一个权威位置；代码、配置、模块状态和验证记录各有归属，见 CONTRIBUTING。
- 功能模块之间不互相 import；Core 不依赖 UI，云服务不依赖 App。新增能力先确定所属模块。
- 在故障源修复；不能吞错、伪造成功、删除失败测试或放宽检查来获得通过结果。
- 重要判断区分事实、假设、未知；工具输出、读过的代码或官方来源才是技术证据。
- 文档、手写注释、提交说明使用中文；标识符和协议字段使用英文。编译器指令、生成内容与第三方原文除外。
- 本项目为公开仓库；每次提交前审查暂存内容，每次推送前审查全部待推送提交及元数据。发现凭证、个人信息或未授权材料必须先处理，执行 [公开仓库审查](docs/PUBLIC-REVIEW.md)，不能以测试通过代替审查。
- 不覆盖或回滚他人的未提交修改。既有 HEAD 之后采用任务分支与独立 worktree；无首个提交时的初始化例外见 CONTRIBUTING。
- 当前任务已授权的跨模块改动可以连续完成；先列影响面并同步调用方，不为普通重构引入额外审批。
- 并行工作先明确各自目录和共享文件负责人；本文件不要求自动启动子 agent。
- 网络、进程、磁盘工作遵守取消和超时约定。真实网络修复走类型化授权边界；不执行个人恢复脚本代替实现。
- 完成汇报写清改动、实际验证和未验证范围。接口占位、mock 测试与进程启动不能冒充完整功能验收。

## 常用命令

```bash
make lint       # 格式、目录、依赖、文档链接、配置检查
make format     # 按 .swift-format 修改格式
make check      # lint + SwiftPM 构建 + 离线测试
make check-all  # 再加原生 Xcode App 构建
make run        # 构建并启动本地开发包
```

按 [验证矩阵](docs/TESTING.md) 选择检查。未通过相关检查不得声称完成或提交；环境阻塞需如实说明，完成其余独立检查。

## 目录地图

| 位置 | 责任 |
| --- | --- |
| `Sources/KaiwuApp` | 场景、导航、组合根 |
| `Sources/KaiwuCore` / `KaiwuUI` | 基础服务 / 可复用原生 UI |
| `Sources/*Feature` | 功能入口、模型、服务与视图 |
| `Sources/CloudServices` | 云账户与同步边界 |
| `Tests` | 同名模块的行为验证 |
| `Tools/RepositoryChecks` | 可执行的仓库规则 |
| `Configuration` / `script` / `.github` | 配置、开发入口与 CI |
| `Integrations` | 引擎及特权助手的接入约束 |
| `docs` | 设计、任务边界、决策与证据索引 |
