@testable import NetworkFeature
import Foundation
import KaiwuCore
import Testing

private struct FixtureReader: ServiceProxyReading {
    let services: [ServiceProxyConfiguration]
    func read() async throws -> [ServiceProxyConfiguration] { services }
}

private actor FixtureLocalProbe: LocalProxyProbing {
    var portCalls = 0
    var pacCalls = 0
    func port(host: String, port: Int) async throws -> DiagnosticLevel { portCalls += 1; return .warning }
    func pac(url: URL) async throws -> DiagnosticLevel { pacCalls += 1; return .pass }
}

@Test func storedProxyParsingKeepsDisabledMalformedAndAutoDiscoveryStates() {
    let config = SystemServiceProxyReader.parse(
        name: "Example Service", enabled: true,
        values: [
            "HTTPEnable": 1, "HTTPProxy": "127.0.0.1", "HTTPPort": 7890,
            "HTTPSEnable": 0, "SOCKSEnable": "unexpected",
            "ProxyAutoConfigEnable": 1, "ProxyAutoConfigURLString": "http://localhost/proxy.pac",
            "ProxyAutoDiscoveryEnable": 1,
        ])
    #expect(config.endpoints.count == 1)
    #expect(config.endpoints[0].port == 7890)
    #expect(config.autoDiscovery)
    #expect(config.issue != nil)
    let fractional = SystemServiceProxyReader.parse(
        name: "Invalid Port", enabled: true,
        values: [
            "HTTPEnable": 1, "HTTPProxy": "127.0.0.1", "HTTPPort": 7890.5,
        ])
    #expect(fractional.issue != nil)
    #expect(fractional.endpoints[0].port == 0)
    if case .enabled(let url) = config.pac {
        #expect(url == "http://localhost/proxy.pac")
    } else {
        Issue.record("PAC 配置未保留")
    }
}

@Test func proxyDiagnosticsSkipDisabledRemoteAndCredentialPACAndReuseLocalChecks() async throws {
    let probe = FixtureLocalProbe()
    let local = ProxyEndpoint(kind: .http, host: "127.0.0.1", port: 7890)
    let services: [ServiceProxyConfiguration] = [
        .init(name: "Disabled", enabled: false, endpoints: [local], pac: .enabled("http://localhost/proxy.pac")),
        .init(
            name: "Local", endpoints: [local, .init(kind: .https, host: "127.0.0.1", port: 7890)],
            pac: .enabled("http://localhost/proxy.pac")),
        .init(
            name: "Remote", endpoints: [.init(kind: .socks, host: "proxy.example.com", port: 1080)],
            pac: .enabled("https://example.com/proxy.pac")),
        .init(name: "Credential", pac: .enabled("http://localhost/proxy.pac?token=example")),
        .init(
            name: "Invalid", endpoints: [.init(kind: .http, host: "", port: 0)], pac: .enabled("file:///example.pac")),
    ]
    let findings = try await ServiceProxyDiagnostics(reader: FixtureReader(services: services), probe: probe).diagnose()
    #expect(await probe.portCalls == 1)
    #expect(await probe.pacCalls == 1)
    #expect(findings.first?.level == .info)
    #expect(findings.filter { $0.level == .warning }.count == 4)
    #expect(findings.contains { $0.id == "service-1-PAC" && $0.level == .pass })
}

@Test func loopbackValidationDoesNotResolveOrAcceptRemoteHosts() {
    for value in ["127.0.0.1", "127.2.3.4", "::1", "[::1]", "0:0:0:0:0:0:0:1", "::ffff:127.0.0.1", "localhost"] {
        #expect(!LocalProxyProbe.loopbackHosts(value).isEmpty)
    }
    for value in [
        "127.0.0.1.example.com", "localhost.example.com", "127.999.0.1", "192.0.2.1", "::", "::ffff:192.0.2.1", "-v",
        "",
    ] {
        #expect(LocalProxyProbe.loopbackHosts(value).isEmpty)
    }
}

private actor CommandRecorder: CommandRunning {
    var commands: [Command] = []
    func run(_ command: Command) async throws -> CommandResult {
        commands.append(command)
        return .init(status: 0, output: command.executable.lastPathComponent == "curl" ? "200" : "")
    }
}

@Test func localProbeUsesBoundedArgumentsAndRefusesSensitivePAC() async throws {
    let runner = CommandRecorder()
    let probe = LocalProxyProbe(runner: runner)
    #expect(try await probe.port(host: "::1", port: 7890) == .pass)
    #expect(try await probe.pac(url: URL(string: "http://127.0.0.1:7890/proxy.pac")!) == .pass)
    #expect(try await probe.pac(url: URL(string: "http://localhost:7890/proxy.pac")!) == .pass)
    await #expect(throws: CommandError.self) {
        try await probe.pac(url: URL(string: "http://localhost/pac?secret=example")!)
    }
    await #expect(throws: CommandError.self) { try await probe.port(host: "example.com", port: 443) }
    let commands = await runner.commands
    #expect(commands.count == 3)
    #expect(commands[0].arguments == ["-n", "-z", "-G", "2", "-w", "2", "::1", "7890"])
    #expect(commands.allSatisfy { $0.timeout <= 4 })
    #expect(commands[1].arguments.contains("--noproxy") && commands[1].arguments.contains("--head"))
    #expect(!commands[1].arguments.contains("--location"))
    // curl 只在首个参数为 --disable 时忽略用户配置，localhost 的解析参数也不能抢占首位。
    #expect(commands.dropFirst().allSatisfy { $0.arguments.first == "--disable" })
    #expect(commands[2].arguments.contains("localhost:7890:127.0.0.1,[::1]"))
}

@Test func reportExportNeverIncludesUserControlledText() {
    let secret = "example-sensitive-token"
    let report = NetworkReport(
        date: Date(timeIntervalSince1970: 0),
        findings: [
            .init(id: "dns-config", title: secret, level: .warning, detail: "192.0.2.15 /Users/example " + secret),
            .init(
                id: "service-0-PAC", title: "Private Service", level: .unavailable,
                detail: "https://example.com/?token=" + secret),
            .init(id: secret, title: secret, level: .failure, detail: secret),
        ], repairPlan: .init(suggestions: [secret]))
    let text = NetworkReportExport.text(report)
    for value in [secret, "192.0.2.15", "/Users/", "Private Service", "example.com"] { #expect(!text.contains(value)) }
    #expect(text.contains("DNS 配置：需留意"))
    #expect(text.contains("未取得结果"))
}

private struct OfflineHTTPS: HTTPSProbing {
    func check(url: URL) async -> DiagnosticFinding {
        Issue.record("关闭外部探测后不应调用 HTTPS 服务")
        return .init(id: "system-https", title: "Test", level: .failure, detail: "")
    }
}

@Test func externalProbesCanBeDisabledWithoutRunningDNSOrHTTP() async throws {
    let runner = CommandRecorder()
    let service = SystemNetworkDiagnostics(
        runner: runner, httpsProbe: OfflineHTTPS(),
        serviceProxies: .init(reader: FixtureReader(services: []), probe: FixtureLocalProbe()))
    let report = try await service.diagnose(url: URL(string: "https://example.com")!, externalProbes: false)
    let commands = await runner.commands
    #expect(commands.count == 5)
    #expect(!commands.contains { ["curl", "dig", "dscacheutil"].contains($0.executable.lastPathComponent) })
    #expect(report.findings.filter { $0.detail.contains("未运行") }.count == 4)
}
