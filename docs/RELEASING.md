# 构建与发布边界

## 开发包

`make build` 使用 SwiftPM 生成 `apps/macos/dist/Kaiwu.app` 并 ad-hoc 签名，不发布、不公证、不启用云服务。应用元数据读取 App.xcconfig，Info.plist 的构建变量由脚本展开。

`PRODUCT_NAME` 用于工程产品、可执行文件和包文件名；`APP_DISPLAY_NAME` 用于系统与界面展示。两者分别为 `Kaiwu` 与「开物 Kaiwu」。发布时核实包内 `CFBundleExecutable`、`CFBundleName`、`CFBundleDisplayName`，不要仅检查文件名。

`apps/macos/Configuration/Local.xcconfig` 仅供 Xcode 本地签名覆盖，不由 shell 执行或解析；不要把它作为版本的第二来源。修改正式产品标识时更新 App.xcconfig，并校验 Xcode scheme / product 引用。

## 版本纪律

版本只在 App.xcconfig 维护；已发行构建号不能回退或重复。引擎版本由对应集成清单固定，“下载最新版”不作为可复现构建。

当前没有发布工作流和自动更新服务。代码整理、格式或文档变更不自行抬版本，实际发行时由发布任务汇总用户可见变化。

未发布内容写入 [changelog/Unreleased.md](../changelog/Unreleased.md)；正式发布时按 [变更记录约定](../changelog/README.md) 归档版本、日期和平台范围。

## 正式发布前

1. 确定 [OPEN-ITEMS](OPEN-ITEMS.md) 中与发行相关的选择，完成许可和隐私说明。
2. `make check-all` 通过，完成目标系统/架构、实际引擎和权限相关验收。
3. 使用真实 Team/Developer ID 签名，检查嵌套引擎、助手、entitlements 和 hardened runtime。
4. 公证、staple，在干净环境验证 Gatekeeper、首次运行、升级和卸载/恢复。
5. 检查最终分发包，排除测试数据、个人配置、日志和凭证，确认第三方声明随包交付。
6. 发布任务明确授权后，再创建 tag、上传或对外发布。

以上是发行要求，不表示能力已经实现。[基础 ADR](decisions/0001-app-foundation.md) 和 [CloudKit 配置](CLOUDKIT.md) 继续约束对应能力。
