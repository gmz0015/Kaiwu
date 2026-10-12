import Darwin
import Foundation
import KaiwuCore

public protocol LocalProxyProbing: Sendable {
    func port(host: String, port: Int) async throws -> DiagnosticLevel
    func pac(url: URL) async throws -> DiagnosticLevel
}

/// 仅连接数值回环地址，不进行主机名解析、网段扫描、PAC 执行或重定向。
public struct LocalProxyProbe: LocalProxyProbing {
    private let runner: any CommandRunning
    public init(runner: any CommandRunning = ProcessRunner()) { self.runner = runner }

    public static func loopbackHosts(_ host: String) -> [String] {
        let value = host.lowercased()
        if value == "localhost" { return ["127.0.0.1", "::1"] }
        let plain = value.hasPrefix("[") && value.hasSuffix("]") ? String(value.dropFirst().dropLast()) : value
        var ipv4 = in_addr()
        if inet_pton(AF_INET, plain, &ipv4) == 1 {
            return withUnsafeBytes(of: ipv4) { $0.first == 127 ? [plain] : [] }
        }
        var ipv6 = in6_addr()
        if inet_pton(AF_INET6, plain, &ipv6) == 1 {
            return withUnsafeBytes(of: ipv6) { bytes in
                let loopback = bytes.prefix(15).allSatisfy { $0 == 0 } && bytes[15] == 1
                let mapped =
                    bytes.prefix(10).allSatisfy { $0 == 0 } && bytes[10] == 255 && bytes[11] == 255 && bytes[12] == 127
                return loopback || mapped ? [plain] : []
            }
        }
        return []
    }

    public func port(host: String, port: Int) async throws -> DiagnosticLevel {
        let hosts = Self.loopbackHosts(host)
        guard !hosts.isEmpty, (1...65535).contains(port) else { throw CommandError.failed("无效的本机代理端口。") }
        for address in hosts {
            try Task.checkCancellation()
            let result = try await runner.run(
                Command(
                    "/usr/bin/nc",
                    arguments: [
                        "-n", "-z", "-G", "2", "-w", "2", address, String(port),
                    ], timeout: 3))
            if result.status == 0 { return .pass }
        }
        return .warning
    }

    public func pac(url: URL) async throws -> DiagnosticLevel {
        guard ["http", "https"].contains(url.scheme), let host = url.host,
            !Self.loopbackHosts(host).isEmpty, url.user == nil, url.password == nil,
            url.query == nil, url.fragment == nil, (1...65535).contains(url.port ?? 80)
        else {
            throw CommandError.failed("只探测不含凭证和查询参数的本机 HTTP(S) PAC 地址。")
        }
        try Task.checkCancellation()
        let resolve =
            host.lowercased() == "localhost"
            ? ["--resolve", "localhost:\(url.port ?? (url.scheme == "https" ? 443 : 80)):127.0.0.1,[::1]"] : []
        let result = try await runner.run(
            Command(
                "/usr/bin/curl",
                arguments: ["--disable"] + resolve + [
                    "--noproxy", "*", "--silent", "--head", "--max-time", "3", "--max-redirs", "0",
                    "--output", "/dev/null", "--write-out", "%{http_code}", "--", url.absoluteString,
                ], timeout: 4))
        guard result.status == 0, let code = Int(result.output) else { return .warning }
        return (200..<300).contains(code) ? .pass : .warning
    }
}
