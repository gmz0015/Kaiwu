import Foundation
import KaiwuCore
import SystemConfiguration

/// 只读已存储的服务配置，不调用任何 Set / Commit / Apply 接口。
public actor SystemServiceProxyReader: ServiceProxyReading {
    public init() {}

    public func read() async throws -> [ServiceProxyConfiguration] {
        try Task.checkCancellation()
        guard let preferences = SCPreferencesCreate(nil, "Kaiwu" as CFString, nil),
            let services = SCNetworkServiceCopyAll(preferences) as? [SCNetworkService]
        else {
            throw CommandError.failed("无法读取网络服务配置。")
        }
        return try services.map { service in
            try Task.checkCancellation()
            let name = SCNetworkServiceGetName(service) as String? ?? "未命名服务"
            let enabled = SCNetworkServiceGetEnabled(service)
            guard let proxy = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies) else {
                return ServiceProxyConfiguration(name: name, enabled: enabled, issue: "此服务没有可读取的代理协议配置。")
            }
            guard let values = SCNetworkProtocolGetConfiguration(proxy) as? [String: Any] else {
                return ServiceProxyConfiguration(name: name, enabled: enabled, issue: "代理配置不可用。")
            }
            return Self.parse(name: name, enabled: enabled && SCNetworkProtocolGetEnabled(proxy), values: values)
        }.sorted { $0.name < $1.name }
    }

    static func parse(name: String, enabled: Bool, values: [String: Any]) -> ServiceProxyConfiguration {
        var endpoints: [ProxyEndpoint] = []
        var invalid = false
        func flag(_ key: String) -> Bool {
            guard let value = values[key] else { return false }
            guard let number = value as? NSNumber, number == 0 || number == 1 else { invalid = true; return false }
            return number == 1
        }
        for (kind, prefix) in [(ProxyEndpoint.Kind.http, "HTTP"), (.https, "HTTPS"), (.socks, "SOCKS")] {
            if flag(prefix + "Enable") {
                let host = values[prefix + "Proxy"] as? String ?? ""
                let number = values[prefix + "Port"] as? NSNumber
                var port = number?.intValue ?? 0
                if let number, number.doubleValue != Double(port) { invalid = true; port = 0 }
                endpoints.append(.init(kind: kind, host: host, port: port))
            }
        }
        let pac: PACConfiguration =
            flag("ProxyAutoConfigEnable")
            ? .enabled(values["ProxyAutoConfigURLString"] as? String ?? "") : .disabled
        let autoDiscovery = flag("ProxyAutoDiscoveryEnable")
        return .init(
            name: name, enabled: enabled, endpoints: endpoints, pac: pac,
            autoDiscovery: autoDiscovery, issue: invalid ? "部分代理字段格式无效，不能判断其状态。" : nil)
    }
}
