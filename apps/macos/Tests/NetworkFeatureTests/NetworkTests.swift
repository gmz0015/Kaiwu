import KaiwuCore
import Foundation
import NetworkFeature
import Testing

@Test func fakeIPRangeCoversTheEntireSlash15() {
    for address in ["198.18.0.0", "198.18.1.1", "198.19.255.255"] { #expect(NetworkParser.isFakeIPv4(address)) }
    for address in ["198.17.1.1", "198.20.1.1", "198.18.999.1", "198.18.x.1", "198.18.1", "198..18.1.1", "::1"] {
        #expect(!NetworkParser.isFakeIPv4(address))
    }
}

@Test func tunnelDetectionDoesNotFlagEveryVPN() {
    let fixture = """
        utun0: flags=8051<UP>
        \tinet6 fe80::1 prefixlen 64
        utun7: flags=8051<UP>
        \tinet 198.19.0.1 netmask 0xfffffffc
        en0: flags=8863<UP>
        \tinet 198.18.0.2 netmask 0xffffff00
        """
    #expect(NetworkParser.fakeIPTunnelInterfaces(in: fixture) == ["utun7"])
}

@Test func parsesSystemResolverAndRouteFields() {
    #expect(
        NetworkParser.systemAddresses(in: "name: example.com\nip_address: 1.2.3.4\nipv6_address: 2001:db8::1\n") == [
            "1.2.3.4", "2001:db8::1",
        ])
    #expect(NetworkParser.value("interface", in: "   gateway: 10.0.0.1\n interface: en0") == "en0")
}

private struct FailedRunner: CommandRunning {
    func run(_ command: Command) async throws -> CommandResult {
        .init(status: 1, output: "", errorOutput: "unavailable")
    }
}
private struct StubHTTPS: HTTPSProbing {
    func check(url: URL) async -> DiagnosticFinding {
        .init(id: "system-https", title: "Test", level: .unavailable, detail: "Offline fixture")
    }
}

@Test func failedProbesNeverReportHealthy() async throws {
    let report = try await SystemNetworkDiagnostics(runner: FailedRunner(), httpsProbe: StubHTTPS())
        .diagnose(url: URL(string: "https://example.com")!)
    #expect(report.findings.count == 9)
    #expect(report.findings.allSatisfy { $0.level == .unavailable })
    #expect(report.repairPlan.proposedActions.isEmpty)
}

@Test func diagnosticRejectsNonHTTPSURLs() async {
    await #expect(throws: CommandError.self) {
        try await SystemNetworkDiagnostics(runner: FailedRunner(), httpsProbe: StubHTTPS())
            .diagnose(url: URL(string: "file:///etc/hosts")!)
    }
}

@Test func privilegedRepairIsUnavailableByDefault() async {
    await #expect(throws: RepairError.self) { try await UnavailableRepairService().execute([.flushDNSCache]) }
}
