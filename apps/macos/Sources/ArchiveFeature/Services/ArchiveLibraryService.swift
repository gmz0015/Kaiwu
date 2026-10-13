import Foundation
import KaiwuCore

/// 只保存本机书签与成功记录；所有磁盘操作由 actor 串行处理，损坏数据不会被自动覆盖。
public actor ArchiveLibraryService {
    private let file: URL
    public static let historyEnabledKey = "archive.historyEnabled"
    public static let historyLimit = 20

    public init(file: URL = URL.applicationSupportDirectory.appendingPathComponent("Kaiwu/ArchiveLibrary.json")) {
        self.file = file
    }

    public func load() throws -> ArchiveLibrary {
        guard FileManager.default.fileExists(atPath: file.path) else { return ArchiveLibrary() }
        do { return try JSONDecoder().decode(ArchiveLibrary.self, from: Data(contentsOf: file)) } catch {
            throw CommandError.failed("无法读取打包记录。请先备份本机 ArchiveLibrary.json，或在设置中清除记录后重试。")
        }
    }

    public func remember(source: URL, receipt: ArchiveReceipt, preset: ArchivePreset) throws -> ArchiveLibrary {
        var library = try load()
        let item = try ArchiveHistoryItem(
            id: UUID(), date: Date(), sourceName: source.lastPathComponent,
            destinationName: receipt.destination.lastPathComponent, sourceBookmark: bookmark(source),
            destinationBookmark: bookmark(receipt.destination), fileCount: receipt.fileCount,
            skippedCount: receipt.skippedCount, preset: preset)
        library.history.insert(item, at: 0)
        library.history = Array(library.history.prefix(Self.historyLimit))
        try save(library)
        return library
    }

    public func addBookmark(_ url: URL) throws -> ArchiveLibrary {
        var library = try load()
        // 重复选择相同目录时更新书签；失效书签仍保留，供用户单独移除。
        let directory = url.resolvingSymlinksInPath().standardizedFileURL
        let data = try bookmark(directory)
        library.bookmarks.removeAll { item in
            var stale = false
            // 此可选解析仅用于去重，解析失败不会隐去原有书签。
            let resolved = try? URL(
                resolvingBookmarkData: item.data, options: [.withoutUI, .withoutMounting],
                bookmarkDataIsStale: &stale)
            return resolved?.resolvingSymlinksInPath().standardizedFileURL == directory
        }
        library.bookmarks.insert(.init(id: UUID(), name: directory.lastPathComponent, data: data), at: 0)
        library.bookmarks = Array(library.bookmarks.prefix(20))
        try save(library)
        return library
    }

    public func resolveBookmark(_ id: UUID) throws -> URL {
        var library = try load()
        guard let index = library.bookmarks.firstIndex(where: { $0.id == id }) else {
            throw CommandError.failed("书签已移除，请重新选择目录。")
        }
        var stale = false
        let url = try resolve(library.bookmarks[index].data, stale: &stale)
        guard (try url.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true else {
            throw CommandError.failed("书签目录不可用，请重新选择目录。")
        }
        if stale {
            library.bookmarks[index].data = try bookmark(url)
            try save(library)
        }
        return url
    }

    public func resolveHistory(_ id: UUID, source: Bool) throws -> URL {
        guard let item = try load().history.first(where: { $0.id == id }) else {
            throw CommandError.failed("历史记录已移除。")
        }
        var stale = false
        let url = try resolve(source ? item.sourceBookmark : item.destinationBookmark, stale: &stale)
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
        guard source ? values.isDirectory == true : values.isRegularFile == true else {
            throw CommandError.failed("文件已移动、删除或磁盘未连接，请重新选择。")
        }
        return url
    }

    public func removeBookmark(_ id: UUID) throws -> ArchiveLibrary {
        var library = try load()
        library.bookmarks.removeAll { $0.id == id }
        try save(library)
        return library
    }

    public func clearHistory() throws -> ArchiveLibrary {
        var library = try load()
        library.history = []
        try save(library)
        return library
    }

    /// 显式清除本模块的记录文件；不会删除源目录或导出的 ZIP。
    public func reset() throws {
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
    }

    private func bookmark(_ url: URL) throws -> Data {
        // 与打包服务使用同一真实路径，避免书签指向符号链接本身而无法再次选用。
        try url.resolvingSymlinksInPath().standardizedFileURL.bookmarkData(
            options: [.withoutImplicitSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    private func resolve(_ data: Data, stale: inout Bool) throws -> URL {
        do {
            let url = try URL(
                resolvingBookmarkData: data, options: [.withoutUI, .withoutMounting], bookmarkDataIsStale: &stale)
            guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else {
                throw CommandError.failed("文件不可用。")
            }
            return url.resolvingSymlinksInPath().standardizedFileURL
        } catch { throw CommandError.failed("书签已失效或磁盘未连接，请重新选择目录或文件。") }
    }

    private func save(_ library: ArchiveLibrary) throws {
        let fm = FileManager.default
        try fm.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        try JSONEncoder().encode(library).write(to: file, options: [.atomic])
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }
}
