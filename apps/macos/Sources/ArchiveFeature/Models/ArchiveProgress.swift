import Foundation

public struct ArchiveProgress: Sendable {
    public enum Phase: String, Sendable {
        case scanning = "扫描目录"
        case copying = "准备文件"
        case compressing = "压缩 ZIP"
        case verifying = "核对源目录"
        case saving = "保存 ZIP"
    }
    public let phase: Phase
    public let completedBytes: Int64
    public let totalBytes: Int64
    public let fileCount: Int
    public let skippedCount: Int

    public init(
        phase: Phase, completedBytes: Int64 = 0, totalBytes: Int64 = 0,
        fileCount: Int = 0, skippedCount: Int = 0
    ) {
        self.phase = phase
        self.completedBytes = completedBytes
        self.totalBytes = totalBytes
        self.fileCount = fileCount
        self.skippedCount = skippedCount
    }
}

public enum ArchivePreset: String, CaseIterable, Codable, Sendable {
    case standard
    case development

    public static let preferenceKey = "archive.preset"
    public var title: String { self == .standard ? "普通文件" : "开发项目" }
    public var policy: ArchivePolicy { .init(excludeDevelopmentArtifacts: self == .development) }
    public var detail: String {
        self == .standard ? "保留项目依赖与版本记录。" : "额外排除 .git、.build、node_modules、DerivedData。"
    }
}
