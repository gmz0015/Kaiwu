@testable import ArchiveFeature
import Foundation
import Testing

@Test func archiveLibraryPersistsBookmarksAndLimitsSuccessHistory() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("source")
    try fm.createDirectory(at: source, withIntermediateDirectories: true)
    let zip = root.appendingPathComponent("result.zip")
    try Data("fixture".utf8).write(to: zip)
    let file = root.appendingPathComponent("state/library.json")
    let store = ArchiveLibraryService(file: file)
    _ = try await store.addBookmark(source)
    let bookmarks = try await store.addBookmark(source)
    #expect(bookmarks.bookmarks.count == 1)
    let resolved = try await store.resolveBookmark(bookmarks.bookmarks[0].id)
    #expect(resolved.resolvingSymlinksInPath() == source.resolvingSymlinksInPath())
    for _ in 0..<23 {
        _ = try await store.remember(
            source: source,
            receipt: ArchiveReceipt(destination: zip, fileCount: 3, skippedCount: 1), preset: .development)
    }
    let loaded = try await ArchiveLibraryService(file: file).load()
    #expect(loaded.history.count == ArchiveLibraryService.historyLimit)
    #expect(loaded.history.allSatisfy { $0.preset == .development })
    let historyURL = try await store.resolveHistory(loaded.history[0].id, source: false)
    #expect(historyURL.resolvingSymlinksInPath() == zip.resolvingSymlinksInPath())
    let cleared = try await store.clearHistory()
    #expect(cleared.history.isEmpty && cleared.bookmarks.count == 1)
    try await store.reset()
    #expect(try await store.load().bookmarks.isEmpty)
    #expect(fm.fileExists(atPath: zip.path))
    #expect(fm.fileExists(atPath: source.path))
}

@Test func corruptLibraryIsNotOverwrittenAndMissingBookmarkIsReported() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("source")
    try fm.createDirectory(at: source, withIntermediateDirectories: true)
    let file = root.appendingPathComponent("library.json")
    let store = ArchiveLibraryService(file: file)
    let library = try await store.addBookmark(source)
    try fm.removeItem(at: source)
    await #expect(throws: (any Error).self) { try await store.resolveBookmark(library.bookmarks[0].id) }
    try Data("corrupt".utf8).write(to: file)
    await #expect(throws: (any Error).self) { try await store.load() }
    await #expect(throws: (any Error).self) { try await store.clearHistory() }
    #expect(try String(contentsOf: file, encoding: .utf8) == "corrupt")
    try await store.reset()
    #expect(try await store.load().history.isEmpty)
}

@Test func bookmarkResolvesDirectoryAfterRename() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let original = root.appendingPathComponent("original")
    let renamed = root.appendingPathComponent("renamed")
    try fm.createDirectory(at: original, withIntermediateDirectories: true)
    let store = ArchiveLibraryService(file: root.appendingPathComponent("library.json"))
    let library = try await store.addBookmark(original)
    try fm.moveItem(at: original, to: renamed)
    let resolved = try await store.resolveBookmark(library.bookmarks[0].id)
    #expect(resolved.resolvingSymlinksInPath() == renamed.resolvingSymlinksInPath())
}
