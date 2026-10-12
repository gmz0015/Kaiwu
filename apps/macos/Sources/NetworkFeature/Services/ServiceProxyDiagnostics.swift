import Foundation

public struct ServiceProxyDiagnostics: Sendable {
    private let reader: any ServiceProxyReading
    private let probe: any LocalProxyProbing

    public init(
        reader: any ServiceProxyReading = SystemServiceProxyReader(), probe: any LocalProxyProbing = LocalProxyProbe()
    ) {
        self.reader = reader
        self.probe = probe
    }

    public func diagnose() async throws -> [DiagnosticFinding] {
        let services: [ServiceProxyConfiguration]
        do { services = try await reader.read() } catch is CancellationError { throw CancellationError() } catch {
            return [.init(id: "service-proxy", title: "按服务代理", level: .unavailable, detail: "无法读取网络服务配置。")]
        }
        if services.isEmpty {
            return [.init(id: "service-proxy", title: "按服务代理", level: .unavailable, detail: "没有可检查的网络服务。")]
        }
        var findings: [DiagnosticFinding] = []
        var ports: [String: DiagnosticLevel] = [:]
        var pacs: [URL: DiagnosticLevel] = [:]
        let deadline = ProcessInfo.processInfo.systemUptime + 30
        for (index, service) in services.enumerated() {
            try Task.checkCancellation()
            let prefix = "service-\(index)"
            if !service.enabled {
                findings.append(
                    .init(
                        id: prefix + "-state", title: service.name, level: .info,
                        detail: "网络服务或代理协议已停用，未探测其端口或 PAC。"))
                continue
            }
            if let issue = service.issue {
                findings.append(.init(id: prefix + "-state", title: service.name, level: .unavailable, detail: issue))
            }
            if service.endpoints.isEmpty, case .disabled = service.pac, service.issue == nil {
                findings.append(
                    .init(
                        id: prefix + "-state", title: service.name, level: .info,
                        detail: "未配置手动 HTTP、HTTPS、SOCKS 或 PAC 代理。"))
            }
            for endpoint in service.endpoints {
                var level: DiagnosticLevel = .info
                var detail: String
                if endpoint.host.isEmpty || !(1...65535).contains(endpoint.port) {
                    level = .warning
                    detail = "代理已启用，但服务器或端口无效。"
                } else if LocalProxyProbe.loopbackHosts(endpoint.host).isEmpty {
                    detail = "已配置远端代理；本次仅检查配置，不连接远端端口。"
                } else {
                    let key = endpoint.host + ":" + String(endpoint.port)
                    if let cached = ports[key] {
                        level = cached
                    } else if ProcessInfo.processInfo.systemUptime >= deadline {
                        level = .unavailable
                    } else {
                        do {
                            level = try await probe.port(host: endpoint.host, port: endpoint.port)
                        } catch is CancellationError { throw CancellationError() } catch { level = .unavailable }
                        ports[key] = level
                    }
                    detail =
                        "本机端口 \(endpoint.port)："
                        + (level == .pass
                            ? "TCP 可连接。此结果不证明代理转发可用。"
                            : level == .warning
                                ? "TCP 未能连接，请检查代理应用是否运行。" : "未取得结果或已达到本轮探测时限。")
                }
                findings.append(
                    .init(
                        id: prefix + "-" + endpoint.kind.rawValue, title: service.name + " · " + endpoint.kind.rawValue,
                        level: level, detail: detail))
            }
            if case .enabled(let value) = service.pac {
                var level: DiagnosticLevel = .info
                var detail: String
                if let url = URL(string: value), ["http", "https"].contains(url.scheme), let host = url.host,
                    !host.isEmpty, (1...65535).contains(url.port ?? 80)
                {
                    if url.user != nil || url.password != nil || url.query != nil || url.fragment != nil {
                        detail = "PAC 地址含凭证、查询参数或片段，未请求；请在系统设置中检查。"
                    } else if LocalProxyProbe.loopbackHosts(host).isEmpty {
                        detail = "远端 PAC 地址格式有效；未下载、执行或验证脚本。"
                    } else {
                        if let cached = pacs[url] {
                            level = cached
                        } else if ProcessInfo.processInfo.systemUptime >= deadline {
                            level = .unavailable
                        } else {
                            do { level = try await probe.pac(url: url) } catch is CancellationError {
                                throw CancellationError()
                            } catch { level = .unavailable }
                            pacs[url] = level
                        }
                        detail =
                            level == .pass
                            ? "本机 PAC 对 HEAD 请求返回 2xx；未验证脚本内容，也未执行。"
                            : level == .warning
                                ? "本机 PAC 未返回 2xx；可能不可用、不支持 HEAD 或发生重定向。"
                                : "PAC 探测未取得结果或已达到本轮探测时限。"
                    }
                } else {
                    level = .warning; detail = "PAC 已启用，但不是有效的 HTTP(S) 地址；未读取或执行。"
                }
                findings.append(
                    .init(id: prefix + "-PAC", title: service.name + " · PAC", level: level, detail: detail))
            }
            if service.autoDiscovery {
                findings.append(
                    .init(
                        id: prefix + "-discovery", title: service.name + " · 自动发现", level: .info,
                        detail: "已启用代理自动发现（WPAD）；本次不执行发现或脚本。"))
            }
        }
        try Task.checkCancellation()
        return findings
    }
}
