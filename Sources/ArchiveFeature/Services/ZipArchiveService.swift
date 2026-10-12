import KaiwuCore
import Foundation

public actor ZipArchiveService: ArchiveServicing {
    private let runner: any CommandRunning
    public init(runner: any CommandRunning = ProcessRunner()) { self.runner = runner }

    public func create(_ request: ArchiveRequest) async throws -> ArchiveReceipt {
        let fm = FileManager.default
        let source = request.source.resolvingSymlinksInPath().standardizedFileURL
        let destination = request.destination.resolvingSymlinksInPath().standardizedFileURL
        guard source.isFileURL, destination.isFileURL,
            (try source.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true
        else {
            throw CommandError.failed("请选择有效的本地目录。")
        }
        guard !Self.isInside(destination, parent: source) else {
            throw CommandError.failed("ZIP 保存位置必须在源目录之外，避免把归档本身打入包中。")
        }
        guard !fm.fileExists(atPath: destination.path) else {
            throw CommandError.failed("目标文件已存在，请选择新的文件名。")
        }
        let staging = fm.temporaryDirectory.resolvingSymlinksInPath()
            .appendingPathComponent("Kaiwu-" + UUID().uuidString)
        guard !Self.isInside(staging, parent: source) else {
            throw CommandError.failed("源目录包含系统临时目录，请选择更具体的目录。")
        }
        try fm.createDirectory(at: staging, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? fm.removeItem(at: staging) }
        let contents = staging.appendingPathComponent("contents", isDirectory: true)
        let payload = contents.appendingPathComponent(source.lastPathComponent, isDirectory: true)
        try fm.createDirectory(at: payload, withIntermediateDirectories: true)
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]
        var enumerationError: Error?
        guard
            let enumerator = fm.enumerator(
                at: source, includingPropertiesForKeys: keys,
                errorHandler: { _, error in
                    enumerationError = error; return false
                })
        else {
            throw CommandError.failed("无法读取目录。")
        }
        var files = 0
        var skipped = 0
        while let item = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            let values = try item.resourceValues(forKeys: Set(keys))
            if request.policy.excludes(component: item.lastPathComponent) || values.isSymbolicLink == true {
                if values.isDirectory == true { enumerator.skipDescendants() }
                skipped += 1
                continue
            }
            let canonicalItem = item.resolvingSymlinksInPath().standardizedFileURL
            guard Self.isInside(canonicalItem, parent: source) else {
                throw CommandError.failed("源目录在打包过程中发生变化，请重试。")
            }
            let relative = canonicalItem.pathComponents.dropFirst(source.pathComponents.count).joined(separator: "/")
            let target = payload.appendingPathComponent(relative)
            if values.isDirectory == true {
                try fm.createDirectory(at: target, withIntermediateDirectories: true)
            } else if values.isRegularFile == true {
                // 复制前再次检查链接；打包策略不包含也不跟随符号链接。
                guard (try item.resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink != true else {
                    skipped += 1
                    continue
                }
                try fm.copyItem(at: item, to: target)
                if (try target.resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink == true {
                    try fm.removeItem(at: target)
                    skipped += 1
                    continue
                }
                files += 1
            } else {
                skipped += 1
            }
        }
        if let enumerationError { throw enumerationError }
        try Task.checkCancellation()
        let zipped = staging.appendingPathComponent("archive.zip")
        let result = try await runner.run(
            Command(
                "/usr/bin/zip",
                arguments: [
                    "-q", "-r", "-X", "-y", zipped.path, "./" + payload.lastPathComponent,
                ], directory: contents, timeout: 300))
        guard result.status == 0 else {
            throw CommandError.failed("ZIP 创建失败：\(result.errorOutput) \(result.output)")
        }
        try Task.checkCancellation()
        // 先复制到目标旁的临时文件，避免跨卷复制时暴露不完整的 ZIP。
        let pending = destination.deletingLastPathComponent().appendingPathComponent(
            ".Kaiwu-\(UUID().uuidString).zip")
        defer { try? fm.removeItem(at: pending) }
        try fm.copyItem(at: zipped, to: pending)
        try Task.checkCancellation()
        try fm.moveItem(at: pending, to: destination)
        return ArchiveReceipt(destination: destination, fileCount: files, skippedCount: skipped)
    }

    private static func isInside(_ url: URL, parent: URL) -> Bool {
        url.pathComponents.starts(with: parent.pathComponents)
    }
}
