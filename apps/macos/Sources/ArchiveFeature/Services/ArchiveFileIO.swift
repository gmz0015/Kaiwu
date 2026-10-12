import Darwin
import Foundation
import KaiwuCore

struct ArchiveFingerprint: Equatable, Sendable {
    let device: dev_t
    let inode: ino_t
    let size: Int64
    let modifiedSeconds: Int
    let modifiedNanos: Int
    let changedSeconds: Int
    let changedNanos: Int
    let mode: mode_t

    init(_ value: stat) {
        device = value.st_dev
        inode = value.st_ino
        size = value.st_size
        modifiedSeconds = value.st_mtimespec.tv_sec
        modifiedNanos = value.st_mtimespec.tv_nsec
        changedSeconds = value.st_ctimespec.tv_sec
        changedNanos = value.st_ctimespec.tv_nsec
        mode = value.st_mode
    }
    var isDirectory: Bool { mode & S_IFMT == S_IFDIR }
    var isFile: Bool { mode & S_IFMT == S_IFREG }
}

struct ArchiveEntry: Equatable, Sendable {
    let relativePath: String
    let fingerprint: ArchiveFingerprint
}

/// 分块读写为大文件提供取消点；文件描述符和快照共同防止把变化的文件静默打包。
enum ArchiveFileIO {
    static func fingerprint(_ url: URL) throws -> ArchiveFingerprint {
        var value = stat()
        guard lstat(url.path, &value) == 0 else { throw posixError() }
        return ArchiveFingerprint(value)
    }

    static func copy(
        _ source: URL, to destination: URL, expected: ArchiveFingerprint,
        check: () throws -> Void,
        progress: (Int64) async -> Void
    ) async throws {
        try check()
        let fd = open(source.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard fd >= 0 else { throw posixError() }
        let input = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        // 关闭失败不改变已经验证的读写结果。
        defer { try? input.close() }
        var before = stat()
        guard fstat(fd, &before) == 0 else { throw posixError() }
        guard ArchiveFingerprint(before) == expected, expected.isFile else { throw changed() }
        let outputFD = open(destination.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard outputFD >= 0 else { throw posixError() }
        let output = FileHandle(fileDescriptor: outputFD, closeOnDealloc: true)
        defer { try? output.close() }
        var copied: Int64 = 0
        while true {
            try check()
            guard let data = try input.read(upToCount: 1024 * 1024), !data.isEmpty else { break }
            try output.write(contentsOf: data)
            copied += Int64(data.count)
            await progress(copied)
        }
        try check()
        var after = stat()
        guard fstat(fd, &after) == 0 else { throw posixError() }
        guard copied == expected.size, ArchiveFingerprint(after) == expected,
            try fingerprint(source) == expected
        else { throw changed() }
        // 保留普通权限和修改时间，不携带 setuid / setgid 等特殊权限。
        guard fchmod(outputFD, expected.mode & 0o777) == 0 else { throw posixError() }
        let timestamp = timespec(tv_sec: expected.modifiedSeconds, tv_nsec: expected.modifiedNanos)
        guard futimens(outputFD, [timestamp, timestamp]) == 0 else { throw posixError() }
        try output.close()
    }

    static func changed() -> CommandError {
        .failed("源目录在打包过程中发生变化，未保存 ZIP。请停止文件写入后重试。")
    }

    private static func posixError() -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
    }
}
