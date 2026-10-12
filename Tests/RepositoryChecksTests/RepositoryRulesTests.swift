import Foundation
import Testing
@testable import RepositoryChecks

@Test func rejectsFeatureToFeatureDependency() {
    let targets = [
        TargetInfo(name: "ArchiveFeature", kind: "regular", path: "", dependencies: ["NetworkFeature"], excludes: []),
        TargetInfo(name: "NetworkFeature", kind: "regular", path: "", dependencies: [], excludes: []),
    ]
    #expect(RepositoryRules.dependencyIssues(targets).count == 1)
}

@Test func rejectsUndeclaredTransitiveImportsAndCoreUIImports() {
    let target = TargetInfo(name: "KaiwuCore", kind: "regular", path: "", dependencies: [], excludes: [])
    let source = "import SwiftUI\n@preconcurrency import NetworkFeature\nimport struct ArchiveFeature.ArchivePolicy\n"
    #expect(
        RepositoryRules.importIssues(
            source: source, target: target,
            moduleNames: ["KaiwuCore", "NetworkFeature", "ArchiveFeature"]
        ).count == 3)
}

@Test func permitsDeclaredDependenciesAndTestableImports() {
    let target = TargetInfo(
        name: "ArchiveFeatureTests", kind: "test", path: "", dependencies: ["ArchiveFeature"], excludes: [])
    #expect(
        RepositoryRules.importIssues(
            source: "@testable import ArchiveFeature\nimport Foundation\n", target: target,
            moduleNames: ["ArchiveFeature"]
        ).isEmpty)
}

@Test func detectsBrokenLinksButIgnoresExampleCodeAndWebURLs() throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString).standardizedFileURL
    try fm.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: root) }
    try Data().write(to: root.appendingPathComponent("exists.md"))
    let markdown =
        "[有效](exists.md#title)\n[失效](missing.md)\n[越界](../outside.md)\n[网络](https://example.com)\n```md\n[示例](example.md)\n```\n"
    #expect(
        RepositoryRules.markdownIssues(markdown, file: root.appendingPathComponent("README.md"), root: root).count == 2)
}

@Test func whitespaceCheckIncludesFilesNotYetTrackedByGit() {
    #expect(RepositoryRules.textIssues("内容\n").isEmpty)
    #expect(!RepositoryRules.textIssues("内容 \n").isEmpty)
    #expect(!RepositoryRules.textIssues("内容\n\n").isEmpty)
    #expect(!RepositoryRules.textIssues("内容").isEmpty)
    #expect(!RepositoryRules.textIssues("内容\r\n").isEmpty)
}

@Test func malformedPackageDumpFailsInsteadOfSilentlySkippingChecks() {
    #expect(throws: CheckError.self) { try RepositoryRules.targets(from: Data("{}".utf8)) }
}
