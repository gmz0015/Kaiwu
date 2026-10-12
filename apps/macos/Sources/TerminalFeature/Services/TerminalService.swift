import AppKit
import Foundation

/// 终端服务边界；后续可将外部启动器替换为内嵌 libghostty 适配器。
@MainActor
public protocol TerminalServicing {
    var isAvailable: Bool { get }
    func open(directory: URL) async throws
}

public struct GhosttyLauncher: TerminalServicing {
    public init() {}
    private var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.mitchellh.ghostty")
    }
    public var isAvailable: Bool { applicationURL != nil }

    public func open(directory: URL) async throws {
        guard let applicationURL else { throw TerminalError.notInstalled }
        guard directory.isFileURL,
            (try directory.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true
        else {
            throw TerminalError.invalidDirectory
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        configuration.arguments = ["--working-directory=" + directory.path]
        _ = try await NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration)
    }
}

public enum TerminalError: LocalizedError {
    case notInstalled, invalidDirectory
    public var errorDescription: String? {
        switch self {
        case .notInstalled: "尚未安装 Ghostty，请先安装后重试。"
        case .invalidDirectory: "请选择有效的本地目录。"
        }
    }
}
