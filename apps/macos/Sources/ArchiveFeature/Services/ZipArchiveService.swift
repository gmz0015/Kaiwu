import Darwin
import Foundation
import KaiwuCore

public actor ZipArchiveService: ArchiveServicing {
    private let runner: any CommandRunning
    private let capacity: @Sendable (URL) throws -> Int64
    private let timeout: TimeInterval

    public init(runner: any CommandRunning = ProcessRunner()) {
        self.runner = runner
        self.capacity = Self.availableCapacity
        self.timeout = 300
    }

    init(
        runner: any CommandRunning = ProcessRunner(), timeout: TimeInterval = 300,
        capacity: @escaping @Sendable (URL) throws -> Int64
    ) {
        self.runner = runner
        self.capacity = capacity
        self.timeout = timeout
    }

    public func create(
        _ request: ArchiveRequest,
        progress: @escaping @Sendable (ArchiveProgress) async -> Void
    ) async throws -> ArchiveReceipt {
        let updates = ArchiveProgressReporter(callback: progress)
        do {
            return try await createArchive(request) { await updates.send($0) }
        } catch is CancellationError { throw CancellationError() } catch let error as CommandError { throw error } catch
        {
            let phase = await updates.phase
            throw CommandError.failed("目录打包在「\(phase.rawValue)」阶段失败：\(error.localizedDescription)")
        }
    }

    private func createArchive(
        _ request: ArchiveRequest,
        progress: @escaping @Sendable (ArchiveProgress) async -> Void
    ) async throws -> ArchiveReceipt {
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        let check: @Sendable () throws -> Void = {
            try Task.checkCancellation()
            if ProcessInfo.processInfo.systemUptime >= deadline { throw CommandError.timedOut }
        }
        try check()
        let fm = FileManager.default
        guard request.source.isFileURL, request.destination.isFileURL else {
            throw CommandError.failed("请选择有效的本地目录和保存位置。")
        }
        let source = request.source.resolvingSymlinksInPath().standardizedFileURL
        let destination = request.destination.standardizedFileURL
        let parent = destination.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL
        let resolvedDestination = parent.appendingPathComponent(destination.lastPathComponent)
        let rootFingerprint = try ArchiveFileIO.fingerprint(source)
        guard rootFingerprint.isDirectory else { throw CommandError.failed("请选择有效的本地目录。") }
        guard !Self.isInside(resolvedDestination, parent: source) else {
            throw CommandError.failed("ZIP 保存位置必须在源目录之外，避免把归档本身打入包中。")
        }
        guard !fm.fileExists(atPath: resolvedDestination.path) else {
            throw CommandError.failed("目标文件已存在，请选择新的文件名。")
        }
        let staging = fm.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(
            "Kaiwu-" + UUID().uuidString)
        guard !Self.isInside(staging, parent: source) else {
            throw CommandError.failed("源目录包含系统临时目录，请选择更具体的目录。")
        }
        try fm.createDirectory(at: staging, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        // 失败时清理暂存副本；清理失败不能将原操作误报为成功。
        defer { try? fm.removeItem(at: staging) }
        await progress(.init(phase: .scanning))
        let snapshot = try await scan(source, policy: request.policy, check: check, progress: progress)
        let bytes = snapshot.entries.filter { $0.fingerprint.isFile }.reduce(Int64(0)) { $0 + $1.fingerprint.size }
        // ZIP 可能比源数据略大，预留目录记录和压缩开销；仍保留实际写入的磁盘错误。
        let overhead = Int64(snapshot.entries.count) * 1024 + bytes / 10 + 1024 * 1024
        let required = bytes + overhead
        let stagingDevice = try ArchiveFileIO.fingerprint(staging).device
        let destinationDevice = try ArchiveFileIO.fingerprint(parent).device
        try requireCapacity(staging, bytes: bytes + required + (stagingDevice == destinationDevice ? required : 0))
        try requireCapacity(parent, bytes: required)
        let contents = staging.appendingPathComponent("contents", isDirectory: true)
        let payload = contents.appendingPathComponent(source.lastPathComponent, isDirectory: true)
        try fm.createDirectory(at: payload, withIntermediateDirectories: true)
        var completed: Int64 = 0
        var files = 0
        await progress(.init(phase: .copying, totalBytes: bytes, skippedCount: snapshot.skipped))
        for entry in snapshot.entries {
            try check()
            let item = source.appendingPathComponent(entry.relativePath)
            guard Self.isInside(item.resolvingSymlinksInPath(), parent: source),
                try ArchiveFileIO.fingerprint(item) == entry.fingerprint
            else { throw ArchiveFileIO.changed() }
            let target = payload.appendingPathComponent(entry.relativePath)
            if entry.fingerprint.isDirectory {
                try fm.createDirectory(at: target, withIntermediateDirectories: true)
            } else {
                let base = completed
                let count = files
                try await ArchiveFileIO.copy(item, to: target, expected: entry.fingerprint, check: check) { amount in
                    await progress(
                        .init(
                            phase: .copying, completedBytes: base + amount, totalBytes: bytes,
                            fileCount: count, skippedCount: snapshot.skipped))
                }
                completed += entry.fingerprint.size
                files += 1
            }
        }
        await progress(
            .init(
                phase: .compressing, completedBytes: completed, totalBytes: bytes,
                fileCount: files, skippedCount: snapshot.skipped))
        try check()
        let zipped = staging.appendingPathComponent("archive.zip")
        let result = try await runner.run(
            Command(
                "/usr/bin/zip",
                arguments: [
                    "-q", "-r", "-X", "-y", zipped.path, "./" + payload.lastPathComponent,
                ], directory: contents, timeout: max(0.1, deadline - ProcessInfo.processInfo.systemUptime)))
        guard result.status == 0 else { throw CommandError.failed("ZIP 创建失败（退出码 \(result.status)）。") }
        try check()
        await progress(.init(phase: .verifying, fileCount: files, skippedCount: snapshot.skipped))
        let current = try await scan(source, policy: request.policy, check: check, progress: { _ in })
        guard snapshot.entries == current.entries, try ArchiveFileIO.fingerprint(source) == rootFingerprint else {
            throw ArchiveFileIO.changed()
        }
        let pending = parent.appendingPathComponent(".Kaiwu-\(UUID().uuidString).zip")
        // 仅清理本次唯一命名的临时文件，不触碰用户的目标文件。
        defer { try? fm.removeItem(at: pending) }
        let zippedFingerprint = try ArchiveFileIO.fingerprint(zipped)
        try requireCapacity(parent, bytes: zippedFingerprint.size)
        try await ArchiveFileIO.copy(zipped, to: pending, expected: zippedFingerprint, check: check) { amount in
            await progress(
                .init(
                    phase: .saving, completedBytes: amount, totalBytes: zippedFingerprint.size,
                    fileCount: files, skippedCount: snapshot.skipped))
        }
        try check()
        // 同卷排他重命名，原子发布且拒绝覆盖，也不要求目标卷支持硬链接。
        guard renamex_np(pending.path, resolvedDestination.path, UInt32(RENAME_EXCL)) == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        return ArchiveReceipt(destination: resolvedDestination, fileCount: files, skippedCount: snapshot.skipped)
    }

    private func scan(
        _ source: URL, policy: ArchivePolicy, check: () throws -> Void,
        progress: (ArchiveProgress) async -> Void
    ) async throws -> (entries: [ArchiveEntry], skipped: Int) {
        var enumerationError: Error?
        guard
            let enumerator = FileManager.default.enumerator(
                at: source, includingPropertiesForKeys: nil,
                errorHandler: { _, error in
                    enumerationError = error; return false
                })
        else {
            throw CommandError.failed("无法读取目录。")
        }
        var entries: [ArchiveEntry] = []
        var skipped = 0
        while let item = enumerator.nextObject() as? URL {
            try check()
            let fingerprint = try ArchiveFileIO.fingerprint(item)
            if policy.excludes(component: item.lastPathComponent) || (!fingerprint.isDirectory && !fingerprint.isFile) {
                if fingerprint.isDirectory { enumerator.skipDescendants() }
                skipped += 1
                continue
            }
            let canonical = item.resolvingSymlinksInPath().standardizedFileURL
            guard Self.isInside(canonical, parent: source) else { throw ArchiveFileIO.changed() }
            let relative = canonical.pathComponents.dropFirst(source.pathComponents.count).joined(separator: "/")
            entries.append(.init(relativePath: relative, fingerprint: fingerprint))
            if entries.count.isMultiple(of: 128) {
                await progress(.init(phase: .scanning, fileCount: entries.count, skippedCount: skipped))
            }
        }
        if let enumerationError { throw enumerationError }
        return (entries.sorted { $0.relativePath < $1.relativePath }, skipped)
    }

    private func requireCapacity(_ url: URL, bytes: Int64) throws {
        guard try capacity(url) >= bytes else {
            throw CommandError.failed(
                "磁盘可用空间不足，需要为暂存副本和 ZIP 预留至少 \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))。")
        }
    }

    private static func availableCapacity(_ url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        guard let capacity = values.volumeAvailableCapacity else { throw CommandError.failed("无法读取磁盘可用空间。") }
        return Int64(capacity)
    }

    private static func isInside(_ url: URL, parent: URL) -> Bool {
        url.standardizedFileURL.pathComponents.starts(with: parent.pathComponents)
    }
}
