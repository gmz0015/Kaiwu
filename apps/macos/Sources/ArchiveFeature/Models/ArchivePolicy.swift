import Foundation

public struct ArchivePolicy: Sendable {
    public var excludeDevelopmentArtifacts: Bool
    public init(excludeDevelopmentArtifacts: Bool = false) {
        self.excludeDevelopmentArtifacts = excludeDevelopmentArtifacts
    }

    private static let metadata: Set<String> = [
        ".DS_Store", "__MACOSX", ".Spotlight-V100", ".Trashes", ".fseventsd", ".TemporaryItems",
    ]
    private static let development: Set<String> = [".git", ".build", "node_modules", "DerivedData"]

    public func excludes(component: String) -> Bool {
        Self.metadata.contains(component) || component.hasPrefix("._")
            || (excludeDevelopmentArtifacts && Self.development.contains(component))
    }
}

public struct ArchiveRequest: Sendable {
    public let source: URL
    public let destination: URL
    public let policy: ArchivePolicy
    public init(source: URL, destination: URL, policy: ArchivePolicy = .init()) {
        self.source = source
        self.destination = destination
        self.policy = policy
    }
}

public struct ArchiveReceipt: Sendable {
    public let destination: URL
    public let fileCount: Int
    public let skippedCount: Int
}
