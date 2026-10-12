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

@Test func nestedPackageResolvesSourcesTestsAndExplicitToolPaths() throws {
    let manifest = #"""
        {"targets": [
            {"name": "KaiwuCore", "type": "regular", "dependencies": [], "exclude": ["README.md"]},
            {"name": "KaiwuCoreTests", "type": "test", "dependencies": [{"byName": ["KaiwuCore", null]}]},
            {"name": "RepositoryChecks", "type": "executable", "path": "Tools/RepositoryChecks", "dependencies": []}
        ]}
        """#
    let targets = try RepositoryRules.targets(from: Data(manifest.utf8), packagePath: "apps/macos")
    #expect(
        targets.map(\.path) == [
            "apps/macos/Sources/KaiwuCore",
            "apps/macos/Tests/KaiwuCoreTests",
            "apps/macos/Tools/RepositoryChecks",
        ])
    #expect(targets[1].dependencies == ["KaiwuCore"])
}

@Test func repositoryPathsNormalizeAliasesAndRejectOutsideFiles() throws {
    let fm = FileManager.default
    let temporary = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    // 临时目录清理不影响断言结果，清理失败不覆盖测试错误。
    defer { try? fm.removeItem(at: temporary) }
    let root = temporary.appendingPathComponent("repository")
    let nested = root.appendingPathComponent("apps/macos/Sources/KaiwuCore/Example.swift")
    try fm.createDirectory(at: nested.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data().write(to: nested)
    let alias = temporary.appendingPathComponent("alias")
    try fm.createSymbolicLink(at: alias, withDestinationURL: root)
    let outside = temporary.appendingPathComponent("outside.swift")
    try Data().write(to: outside)
    #expect(RepositoryRules.repositoryPath(for: nested, root: alias) == "apps/macos/Sources/KaiwuCore/Example.swift")
    #expect(RepositoryRules.repositoryPath(for: root, root: alias) == nil)
    #expect(RepositoryRules.repositoryPath(for: outside, root: alias) == nil)
}
