import ArchiveFeature
import KaiwuCore
import Foundation
import Testing

@Test func archivePolicyKeepsUsefulDotfiles() {
    let policy = ArchivePolicy()
    for name in [".DS_Store", "._notes", "__MACOSX"] { #expect(policy.excludes(component: name)) }
    for name in [".gitignore", ".env.example", "node_modules", ".git"] { #expect(!policy.excludes(component: name)) }
    #expect(ArchivePolicy(excludeDevelopmentArtifacts: true).excludes(component: "node_modules"))
}

@Test func zipFiltersNestedMetadataAndDoesNotFollowLinks() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("项目 with spaces")
    try fm.createDirectory(at: source.appendingPathComponent("nested"), withIntermediateDirectories: true)
    try fm.createDirectory(at: source.appendingPathComponent("node_modules"), withIntermediateDirectories: true)
    for file in [
        ".DS_Store", "nested/.DS_Store", "._extra", "nested/keep.txt", ".gitignore", "node_modules/package.js",
        "a;$(echo nope).txt",
    ] {
        try Data(file.utf8).write(to: source.appendingPathComponent(file))
    }
    try Data("outside secret".utf8).write(to: root.appendingPathComponent("secret.txt"))
    try fm.createSymbolicLink(
        at: source.appendingPathComponent("link"), withDestinationURL: root.appendingPathComponent("secret.txt"))
    let destination = root.appendingPathComponent("result.zip")
    let receipt = try await ZipArchiveService().create(
        .init(
            source: source, destination: destination,
            policy: .init(excludeDevelopmentArtifacts: true)))
    #expect(receipt.fileCount == 3)
    let listing = try await ProcessRunner().run(Command("/usr/bin/unzip", arguments: ["-Z1", destination.path]))
    #expect(listing.status == 0)
    #expect(listing.output.contains("nested/keep.txt"))
    #expect(listing.output.contains(".gitignore"))
    #expect(listing.output.contains("a;$(echo nope).txt"))
    for name in [".DS_Store", "._extra", "node_modules", "/link", "secret.txt"] {
        #expect(!listing.output.contains(name))
    }
    let integrity = try await ProcessRunner().run(Command("/usr/bin/unzip", arguments: ["-t", destination.path]))
    #expect(integrity.status == 0)
    #expect(fm.fileExists(atPath: source.appendingPathComponent(".DS_Store").path))
}

@Test func archiveRejectsDestinationInsideSourceAndExistingFiles() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("source")
    try fm.createDirectory(at: source, withIntermediateDirectories: true)
    let service = ZipArchiveService()
    await #expect(throws: CommandError.self) {
        try await service.create(.init(source: source, destination: source.appendingPathComponent("self.zip")))
    }
    let existing = root.appendingPathComponent("existing.zip")
    try Data("preserved".utf8).write(to: existing)
    await #expect(throws: CommandError.self) { try await service.create(.init(source: source, destination: existing)) }
    #expect(try String(contentsOf: existing, encoding: .utf8) == "preserved")
}

@Test func emptyDirectoryNamedArchiveZipCanBePacked() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("archive.zip")
    try fm.createDirectory(at: source, withIntermediateDirectories: true)
    let receipt = try await ZipArchiveService().create(
        .init(source: source, destination: root.appendingPathComponent("output.zip")))
    #expect(receipt.fileCount == 0)
    #expect(fm.fileExists(atPath: receipt.destination.path))
}
