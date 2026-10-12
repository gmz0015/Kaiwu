# KaiwuCore

## 职责

提供跨功能的值类型、基础执行能力与任务状态，不依赖界面和具体功能。

## 现状

包含可取消、可超时的进程执行器、页面任务控制器和跨页面偏好的键/默认值。进程执行器只用于受控系统命令。

## 已完成

- [ProcessRunner](Processes/ProcessRunner.swift) 使用参数数组、临时输出文件与受限环境；[命令契约](Processes/CommandRunning.swift) 支持测试替身。
- [ToolTask](Tasks/ToolTask.swift) 统一运行、取消中、成功和失败状态；取消完成前禁止重复启动，业务失败不因并发取消而被掩盖。
- [ToolPreferences](Preferences/ToolPreferences.swift) 集中定义网络地址和外部探测选项，页面和设置共用。

## 下一步

按真实消费者扩展基础能力。任务取消遵循服务契约：服务在可中止阶段抛出 CancellationError；已原子保存的文件或已启动的外部应用可返回成功，不回滚已完成的副作用。

## 验证

[进程测试](../../Tests/KaiwuCoreTests/ProcessRunnerTests.swift) 覆盖参数、取消、超时与大输出；[任务测试](../../Tests/KaiwuCoreTests/ToolTaskTests.swift) 覆盖重复启动、等待取消完成、再次启动和独立失败语义。运行 `make check`。
