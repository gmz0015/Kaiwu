import Foundation

/// 界面和系统包共用构建配置中的名称；预览无应用包时回退到进程名。
enum AppIdentity {
    static let displayName =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? ProcessInfo.processInfo.processName

    static let loggingSubsystem = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
}
