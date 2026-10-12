import Darwin
import Foundation

/// 直接执行参数数组，不经过 shell；使用临时文件避免输出管道阻塞。
public struct ProcessRunner: CommandRunning {
    public init() {}

    public func run(_ command: Command) async throws -> CommandResult {
        let cancellation = CancellationFlag()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await Task.detached(priority: .utility) {
                try Self.execute(command, cancellation: cancellation)
            }.value
        } onCancel: {
            cancellation.cancel()
        }
    }

    private static func execute(_ command: Command, cancellation: CancellationFlag) throws -> CommandResult {
        let fm = FileManager.default
        let folder = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(
            at: folder, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        defer { try? fm.removeItem(at: folder) }
        let outURL = folder.appendingPathComponent("stdout")
        let errURL = folder.appendingPathComponent("stderr")
        fm.createFile(atPath: outURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
        fm.createFile(atPath: errURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
        let out = try FileHandle(forWritingTo: outURL)
        let err = try FileHandle(forWritingTo: errURL)
        defer { try? out.close(); try? err.close() }

        let process = Process()
        process.executableURL = command.executable
        process.arguments = command.arguments
        process.currentDirectoryURL = command.directory
        // 固定子进程环境，不继承 shell 配置、代理变量或用户设置的 ZIP 参数。
        process.environment = [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "en_US.UTF-8", "COPYFILE_DISABLE": "1",
        ]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = out
        process.standardError = err
        if cancellation.isCancelled { throw CancellationError() }
        try process.run()
        let deadline = ProcessInfo.processInfo.systemUptime + command.timeout
        while process.isRunning {
            if cancellation.isCancelled || ProcessInfo.processInfo.systemUptime >= deadline {
                process.terminate()
                let grace = ProcessInfo.processInfo.systemUptime + 0.5
                while process.isRunning && ProcessInfo.processInfo.systemUptime < grace {
                    Thread.sleep(forTimeInterval: 0.02)
                }
                if process.isRunning { Darwin.kill(process.processIdentifier, SIGKILL) }
                process.waitUntilExit()
                if cancellation.isCancelled { throw CancellationError() }
                throw CommandError.timedOut
            }
            Thread.sleep(forTimeInterval: 0.02)
        }
        process.waitUntilExit()
        if cancellation.isCancelled { throw CancellationError() }
        return try CommandResult(
            status: process.terminationStatus,
            output: readBounded(outURL), errorOutput: readBounded(errURL))
    }

    private static func readBounded(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let limit = 512 * 1024
        let data = try handle.read(upToCount: limit + 1) ?? Data()
        let text = String(decoding: data.prefix(limit), as: UTF8.self)
        return data.count > limit ? text + "\n[输出已截断]" : text
    }
}

/// 此类型的每次状态访问都由锁保护，因此显式采用 unchecked Sendable。
private final class CancellationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    var isCancelled: Bool { lock.withLock { cancelled } }
    func cancel() { lock.withLock { cancelled = true } }
}
