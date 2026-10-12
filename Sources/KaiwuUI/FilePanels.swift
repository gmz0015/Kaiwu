import AppKit
import UniformTypeIdentifiers

/// 原生目录与保存面板的 AppKit 桥接，此处不持有视图状态。
@MainActor
public enum FilePanels {
    public static func directory() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择目录"
        return panel.runModal() == .OK ? panel.url : nil
    }

    public static func archive(named name: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = name + ".zip"
        panel.message = "请选择尚不存在的文件名；打包不会覆盖已有文件。"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
