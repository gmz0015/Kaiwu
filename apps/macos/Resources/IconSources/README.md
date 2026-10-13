# 图标原图

这三张透明 PNG 由项目用户提供：`AppIcon.png` 为应用图标，`MenuBarLight.png` 和 `MenuBarDark.png` 分别为浅色、深色菜单栏图形。原图保留用于再生成，不随应用分发。

在仓库根运行 `bash apps/macos/script/generate_icons.sh`，生成 [资源目录](../../Sources/KaiwuApp/Resources/Assets.xcassets) 中的 macOS 16、32、128、256、512 pt（各含 1x / 2x）应用图标，以及 19 × 18 pt（1x / 2x）菜单栏图标。应用原图仅裁去外围透明留白并缩放，菜单栏保持透明通道。

菜单栏资源含两套外观，使用模板渲染，由系统决定当前菜单栏与选中状态的前景颜色。Xcode 自动编译资源目录；SwiftPM 开发包由 [打包脚本](../../script/build_and_run.sh) 调用同一套资源编译工具并合并图标元数据。仅运行 `swift build` 不会生成完整的图形应用包，请使用 `make run`。
