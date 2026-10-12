@testable import ArchiveFeature
import Foundation
import KaiwuCore
import Testing

private struct ArchiveFixture {
    let root: URL
    let source: URL
    let destination: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        source = root.appendingPathComponent("项目")
        destination = root.appendingPathComponent("output.zip")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    }
    func cleanup() { try? FileManager.default.removeItem(at: root) }
    func noPendingFile() throws -> Bool {
        try !FileManager.default.contentsOfDirectory(atPath: root.path).contains { $0.hasPrefix(".Kaiwu-") }
    }
}

private actor ProgressLog {
    var values: [ArchiveProgress] = []
    func append(_ value: ArchiveProgress) { values.append(value) }
}

@Test func archiveLargeTreeReportsRealProgressAndProducesValidZip() async throws {
    let fixture = try ArchiveFixture()
    defer { fixture.cleanup() }
    for i in 0..<2048 {
        let folder = fixture.source.appendingPathComponent("group-\(i / 40)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(repeating: UInt8(i % 255), count: 4096).write(to: folder.appendingPathComponent("file-\(i).txt"))
    }
    try Data(repeating: 65, count: 3 * 1024 * 1024).write(to: fixture.source.appendingPathComponent("large.bin"))
    let log = ProgressLog()
    let receipt = try await ZipArchiveService().create(.init(source: fixture.source, destination: fixture.destination))
    {
        await log.append($0)
    }
    let values = await log.values
    #expect(receipt.fileCount == 2049)
    #expect(Set(values.map(\.phase)) == [.scanning, .copying, .compressing, .verifying, .saving])
    let copying = values.filter { $0.phase == .copying }.map(\.completedBytes)
    #expect(copying == copying.sorted())
    let expectedBytes: Int64 = 2048 * 4096 + 3 * 1024 * 1024
    #expect(copying.last == expectedBytes)
    #expect(values.allSatisfy { $0.completedBytes <= $0.totalBytes })
    let result = try await ProcessRunner().run(Command("/usr/bin/unzip", arguments: ["-t", receipt.destination.path]))
    #expect(result.status == 0)
    #expect(try fixture.noPendingFile())
}

@Test func archiveCancellationInsideLargeFileLeavesNoDestination() async throws {
    let fixture = try ArchiveFixture()
    defer { fixture.cleanup() }
    try Data(repeating: 65, count: 8 * 1024 * 1024).write(to: fixture.source.appendingPathComponent("large.bin"))
    let task = Task {
        try await ZipArchiveService().create(.init(source: fixture.source, destination: fixture.destination)) {
            update in
            if update.phase == .copying, update.completedBytes > 0 { withUnsafeCurrentTask { $0?.cancel() } }
        }
    }
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(!FileManager.default.fileExists(atPath: fixture.destination.path))
    #expect(try fixture.noPendingFile())
    #expect(try Data(contentsOf: fixture.source.appendingPathComponent("large.bin")).count == 8 * 1024 * 1024)
}

@Test func archiveRejectsInsufficientCapacityAndDeadlineBeforePublishing() async throws {
    let fixture = try ArchiveFixture()
    defer { fixture.cleanup() }
    try Data("keep".utf8).write(to: fixture.source.appendingPathComponent("file.txt"))
    let request = ArchiveRequest(source: fixture.source, destination: fixture.destination)
    await #expect(throws: CommandError.self) { try await ZipArchiveService(capacity: { _ in 0 }).create(request) }
    await #expect(throws: CommandError.self) {
        try await ZipArchiveService(timeout: 0, capacity: { _ in Int64.max }).create(request)
    }
    #expect(!FileManager.default.fileExists(atPath: fixture.destination.path))
    #expect(try fixture.noPendingFile())
}

@Test func archiveRejectsChangedSourceAndConcurrentDestination() async throws {
    let fixture = try ArchiveFixture()
    defer { fixture.cleanup() }
    let file = fixture.source.appendingPathComponent("file.txt")
    try Data("original".utf8).write(to: file)
    let request = ArchiveRequest(source: fixture.source, destination: fixture.destination)
    await #expect(throws: CommandError.self) {
        try await ZipArchiveService().create(request) { update in
            if update.phase == .compressing {
                // 回调在压缩前确定性触发，模拟源文件在任务期间被编辑。
                do { try Data("changed".utf8).write(to: file) } catch { Issue.record(error) }
            }
        }
    }
    #expect(!FileManager.default.fileExists(atPath: fixture.destination.path))
    await #expect(throws: (any Error).self) {
        try await ZipArchiveService().create(request) { update in
            if update.phase == .saving {
                do { try Data("owned by another task".utf8).write(to: fixture.destination) } catch {
                    Issue.record(error)
                }
            }
        }
    }
    #expect(try String(contentsOf: fixture.destination, encoding: .utf8) == "owned by another task")
    #expect(try fixture.noPendingFile())
}

private struct BrokenZipRunner: CommandRunning {
    func run(_ command: Command) async throws -> CommandResult { .init(status: 9, output: "", errorOutput: "failure") }
}

@Test func failedCompressionDoesNotLeaveSuccessArtifact() async throws {
    let fixture = try ArchiveFixture()
    defer { fixture.cleanup() }
    await #expect(throws: CommandError.self) {
        try await ZipArchiveService(runner: BrokenZipRunner()).create(
            .init(source: fixture.source, destination: fixture.destination))
    }
    #expect(!FileManager.default.fileExists(atPath: fixture.destination.path))
    #expect(try fixture.noPendingFile())
}

@Test func archivePreservesExecutablePermissionAndModificationTime() async throws {
    let fixture = try ArchiveFixture()
    defer { fixture.cleanup() }
    let file = fixture.source.appendingPathComponent("script.sh")
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    try Data("#!/bin/sh\nexit 0\n".utf8).write(to: file)
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o751, .modificationDate: timestamp], ofItemAtPath: file.path)
    _ = try await ZipArchiveService().create(.init(source: fixture.source, destination: fixture.destination))
    let extracted = fixture.root.appendingPathComponent("extracted")
    let result = try await ProcessRunner().run(
        Command("/usr/bin/unzip", arguments: ["-q", fixture.destination.path, "-d", extracted.path]))
    #expect(result.status == 0)
    let attributes = try FileManager.default.attributesOfItem(
        atPath: extracted.appendingPathComponent("项目/script.sh").path)
    #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o751)
    let date = try #require(attributes[.modificationDate] as? Date)
    #expect(abs(date.timeIntervalSince(timestamp)) < 2)
}

@Test func archiveRejectsLinkReplacementAndCancellationAtSave() async throws {
    let fixture = try ArchiveFixture()
    defer { fixture.cleanup() }
    let file = fixture.source.appendingPathComponent("file.txt")
    let outside = fixture.root.appendingPathComponent("outside.txt")
    try Data("original".utf8).write(to: file)
    try Data("outside".utf8).write(to: outside)
    await #expect(throws: CommandError.self) {
        try await ZipArchiveService().create(.init(source: fixture.source, destination: fixture.destination)) {
            update in
            if update.phase == .copying, update.completedBytes == 0 {
                do {
                    try FileManager.default.removeItem(at: file)
                    try FileManager.default.createSymbolicLink(at: file, withDestinationURL: outside)
                } catch { Issue.record(error) }
            }
        }
    }
    #expect(!FileManager.default.fileExists(atPath: fixture.destination.path))
    let task = Task {
        try await ZipArchiveService().create(.init(source: fixture.source, destination: fixture.destination)) {
            update in
            if update.phase == .saving { withUnsafeCurrentTask { $0?.cancel() } }
        }
    }
    await #expect(throws: CancellationError.self) { try await task.value }
    #expect(!FileManager.default.fileExists(atPath: fixture.destination.path))
    #expect(try fixture.noPendingFile())
    #expect(try String(contentsOf: outside, encoding: .utf8) == "outside")
}
