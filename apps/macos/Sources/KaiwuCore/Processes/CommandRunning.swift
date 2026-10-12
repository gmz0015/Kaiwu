import Foundation

public struct Command: Sendable {
    public let executable: URL
    public let arguments: [String]
    public let directory: URL?
    public let timeout: TimeInterval

    public init(_ path: String, arguments: [String] = [], directory: URL? = nil, timeout: TimeInterval = 10) {
        executable = URL(fileURLWithPath: path)
        self.arguments = arguments
        self.directory = directory
        self.timeout = timeout
    }
}

public struct CommandResult: Sendable {
    public let status: Int32
    public let output: String
    public let errorOutput: String

    public init(status: Int32, output: String, errorOutput: String = "") {
        self.status = status
        self.output = output
        self.errorOutput = errorOutput
    }
}

public protocol CommandRunning: Sendable {
    func run(_ command: Command) async throws -> CommandResult
}

public enum CommandError: LocalizedError {
    case timedOut
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .timedOut: "操作超时，进程已停止。"
        case .failed(let message): message
        }
    }
}
