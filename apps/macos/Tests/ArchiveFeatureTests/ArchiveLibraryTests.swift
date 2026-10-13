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

@Test func bookmarkAliasesReferToOneCanonicalDirectory() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("source")
    let alias = root.appendingPathComponent("alias")
    try fm.createDirectory(at: source, withIntermediateDirectories: true)
    try fm.createSymbolicLink(at: alias, withDestinationURL: source)
    let store = ArchiveLibraryService(file: root.appendingPathComponent("library.json"))
    _ = try await store.addBookmark(source)
    let library = try await store.addBookmark(alias)
    #expect(library.bookmarks.count == 1)
    let resolved = try await store.resolveBookmark(library.bookmarks[0].id)
    #expect(resolved.resolvingSymlinksInPath() == source.resolvingSymlinksInPath())
}

@Test func historyCanReuseASourceSelectedThroughDirectoryAlias() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("source")
    let alias = root.appendingPathComponent("alias")
    let zip = root.appendingPathComponent("result.zip")
    try fm.createDirectory(at: source, withIntermediateDirectories: true)
    try fm.createSymbolicLink(at: alias, withDestinationURL: source)
    try Data("fixture".utf8).write(to: zip)
    let store = ArchiveLibraryService(file: root.appendingPathComponent("library.json"))
    let library = try await store.remember(
        source: alias, receipt: ArchiveReceipt(destination: zip, fileCount: 1, skippedCount: 0), preset: .standard)
    // 新记录保存真实目录，移除链接不应让仍存在的源目录变得不可用。
    try fm.removeItem(at: alias)
    let resolved = try await store.resolveHistory(library.history[0].id, source: true)
    #expect(resolved == source.resolvingSymlinksInPath())
}

@Test func existingAliasBookmarkCanBeResolvedAndDeduplicated() async throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("source")
    let alias = root.appendingPathComponent("alias")
    try fm.createDirectory(at: source, withIntermediateDirectories: true)
    try fm.createSymbolicLink(at: alias, withDestinationURL: source)
    // 模拟旧版本直接为符号链接生成的书签，验证无需清空原记录。
    var library = ArchiveLibrary()
    let id = UUID()
    library.bookmarks = [
        ArchiveBookmark(
            id: id, name: "alias",
            data: try alias.bookmarkData(
                options: [.withoutImplicitSecurityScope], includingResourceValuesForKeys: nil,
                relativeTo: nil))
    ]
    let file = root.appendingPathComponent("library.json")
    try JSONEncoder().encode(library).write(to: file)
    let store = ArchiveLibraryService(file: file)
    #expect(try await store.resolveBookmark(id) == source.resolvingSymlinksInPath())
    #expect(try await store.addBookmark(source).bookmarks.count == 1)
}
