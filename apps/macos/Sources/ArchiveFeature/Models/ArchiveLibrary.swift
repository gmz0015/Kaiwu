import Foundation

public struct ArchiveHistoryItem: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let sourceName: String
    public let destinationName: String
    public let sourceBookmark: Data
    public let destinationBookmark: Data
    public let fileCount: Int
    public let skippedCount: Int
    public let preset: ArchivePreset
}

public struct ArchiveBookmark: Codable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public var data: Data
}

public struct ArchiveLibrary: Codable, Sendable {
    public var history: [ArchiveHistoryItem] = []
    public var bookmarks: [ArchiveBookmark] = []
    public init() {}
}
