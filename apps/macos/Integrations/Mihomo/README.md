# Mihomo 集成边界

当前实现见 `Sources/ProxyFeature/Services/ProxyController.swift`，只连接用户显式填写的本机控制器并读取版本。没有托管核心、导入订阅或修改系统代理。

未来二进制 manifest 应包含 version、来源 URL、SHA-256、架构和许可证位置。引擎不得以未校验下载文件直接运行。详见 [技术决策](../../../../docs/decisions/0002-native-engines.md)。
