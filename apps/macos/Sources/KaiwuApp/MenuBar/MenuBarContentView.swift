import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("打开开物") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("设置…") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("退出开物") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
