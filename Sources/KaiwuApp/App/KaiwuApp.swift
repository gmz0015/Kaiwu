import AppKit
import OSLog
import SwiftUI

@main
struct KaiwuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    private let services = AppServices.live()

    var body: some Scene {
        WindowGroup(AppIdentity.displayName, id: "main") {
            ContentView(modules: services.modules)
                .frame(minWidth: 820, minHeight: 560)
        }
        .defaultSize(width: 1080, height: 720)
        .commands { SidebarCommands() }
        Settings { SettingsView(cloudAccount: services.cloudAccount) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        Logger(subsystem: AppIdentity.loggingSubsystem, category: "lifecycle")
            .info("Application launched")
    }
}
