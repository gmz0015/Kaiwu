import KaiwuCore
import Foundation

public struct SystemNetworkDiagnostics: NetworkDiagnosing {
    private let runner: any CommandRunning
    private let httpsProbe: any HTTPSProbing
    public init(runner: any CommandRunning = ProcessRunner(), httpsProbe: any HTTPSProbing = SystemHTTPSProbe()) {
        self.runner = runner
        self.httpsProbe = httpsProbe
    }

    public func diagnose(url: URL) async throws -> NetworkReport {
        guard url.scheme == "https", let host = url.host, !host.isEmpty,
            url.user == nil, url.password == nil
        else {
            throw CommandError.failed("请输入不含用户名和密码的 HTTPS 地址。")
        }
        var findings: [DiagnosticFinding] = []
        var suggestions: [String] = []
        var actions: [RepairAction] = []
        let commands: [(String, String, Command)] = [
            ("dns-config", "DNS 配置", Command("/usr/sbin/scutil", arguments: ["--dns"])),
            ("default-route", "默认路由", Command("/sbin/route", arguments: ["-n", "get", "default"])),
            ("public-route", "公网出口路由（1.1.1.1）", Command("/sbin/route", arguments: ["-n", "get", "1.1.1.1"])),
            ("interfaces", "TUN / Fake IP 接口", Command("/sbin/ifconfig")),
            ("proxy", "系统动态代理", Command("/usr/sbin/scutil", arguments: ["--proxy"])),
            ("dns", "系统 DNS 解析", Command("/usr/bin/dscacheutil", arguments: ["-q", "host", "-a", "name", host])),
            (
                "external-dns", "外部 DNS 对照（223.5.5.5）",
                Command("/usr/bin/dig", arguments: ["+time=2", "+tries=1", "+short", "@223.5.5.5", host, "A"])
            ),
            (
                "direct", "HTTPS 直连",
                Command(
                    "/usr/bin/curl",
                    arguments: [
                        "--disable", "--noproxy", "*", "--silent", "--show-error", "--max-time", "8",
                        "--output", "/dev/null", "--write-out", "%{http_code}", "--", url.absoluteString,
                    ])
            ),
        ]
        for (id, title, command) in commands {
            try Task.checkCancellation()
            do {
                let result = try await runner.run(command)
                guard result.status == 0 else {
                    findings.append(
                        .init(
                            id: id, title: title, level: .unavailable,
                            detail: "未取得有效结果（退出码 \(result.status)）。\n\(result.errorOutput)"))
                    continue
                }
                var level: DiagnosticLevel = .info
                var detail = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                switch id {
                case "dns":
                    let addresses = NetworkParser.systemAddresses(in: detail)
                    if addresses.isEmpty {
                        level = .warning
                        detail = "系统解析器没有返回地址。"
                        suggestions.append("系统 DNS 未返回地址：请对照外部 DNS 结果，检查当前网络服务的 DNS 设置。")
                    } else if addresses.contains(where: NetworkParser.isFakeIPv4) {
                        level = .warning
                        detail = addresses.joined(separator: ", ") + "\n发现 198.18.0.0/15 地址，可能是正在工作的代理，也可能是缓存残留。"
                        suggestions.append("先确认代理是否仍在使用 Fake IP；只有退出代理后仍异常，才考虑刷新 DNS 缓存。")
                        actions.append(.flushDNSCache)
                    } else {
                        level = .pass; detail = addresses.joined(separator: ", ")
                    }
                case "interfaces":
                    let names = NetworkParser.fakeIPTunnelInterfaces(in: detail)
                    detail =
                        names.isEmpty
                        ? "未发现绑定 198.18.0.0/15 地址的 utun。此检查不覆盖所有 VPN 地址段。"
                        : "发现：\(names.joined(separator: ", "))。接口存在不代表残留，可能是正常运行的 VPN / TUN。"
                    if !names.isEmpty { suggestions.append("核对代理应用中的 TUN 状态，不要批量关闭 utun 接口。") }
                case "proxy":
                    let enabled = ["HTTPEnable", "HTTPSEnable", "SOCKSEnable", "ProxyAutoConfigEnable"]
                        .contains { NetworkParser.value($0, in: detail) == "1" }
                    if enabled { suggestions.append("系统代理已启用；若直连成功但系统路径失败，请检查代理端口或 PAC 服务。") }
                case "direct":
                    let code = Int(detail) ?? 0
                    level = (200..<400).contains(code) ? .pass : .warning
                    detail = "HTTP \(detail)。本项绕过代理；非 2xx/3xx 不一定意味着网络故障。"
                case "external-dns":
                    level = detail.isEmpty ? .warning : .info
                    if detail.isEmpty { detail = "外部 DNS 未返回 A 记录；也可能受当前网络策略限制。" }
                default: break
                }
                if detail.isEmpty { detail = "命令未返回内容。"; level = .unavailable }
                findings.append(.init(id: id, title: title, level: level, detail: detail))
            } catch is CancellationError { throw CancellationError() } catch {
                findings.append(.init(id: id, title: title, level: .unavailable, detail: error.localizedDescription))
            }
        }
        try Task.checkCancellation()
        findings.append(await httpsProbe.check(url: url))
        try Task.checkCancellation()
        if suggestions.isEmpty { suggestions.append("未生成针对性修复建议。请查看各项结果；单次探测不能证明所有网络路径正常。") }
        return NetworkReport(
            date: Date(), findings: findings,
            repairPlan: RepairPlan(suggestions: suggestions, proposedActions: actions))
    }

}
