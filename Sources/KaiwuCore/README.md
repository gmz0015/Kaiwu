# KaiwuCore

## 职责

提供跨功能的值类型与基础执行能力，不依赖界面和具体功能。

## 现状

包含功能描述与可取消、可超时的进程执行器；只用于受控系统命令。

## 已完成

[ProcessRunner](Processes/ProcessRunner.swift) 使用参数数组、临时输出文件与受限环境；[命令契约](Processes/CommandRunning.swift) 提供可替换服务。

## 下一步

按真实消费者需求增加基础能力；避免变成无边界的工具集合。

## 验证

[进程测试](../../Tests/KaiwuCoreTests/ProcessRunnerTests.swift) 覆盖参数、取消、超时、大输出；运行 `make check`。
