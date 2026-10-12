import Foundation

/// 未来同步的数据白名单，不包含终端历史、路径、报告与凭证。
public struct SyncedPreferences: Codable, Equatable, Sendable {
    public var schemaVersion: Int = 1
    public var excludeDevelopmentArtifacts: Bool
    public var modifiedAt: Date
    public init(excludeDevelopmentArtifacts: Bool, modifiedAt: Date = Date()) {
        self.excludeDevelopmentArtifacts = excludeDevelopmentArtifacts
        self.modifiedAt = modifiedAt
    }
}
