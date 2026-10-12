import Foundation

public struct ServiceProxyConfiguration: Sendable {
    public let name: String
    public let enabled: Bool
    public let endpoints: [ProxyEndpoint]
    public let pac: PACConfiguration
    public let autoDiscovery: Bool
    public let issue: String?

    public init(
        name: String, enabled: Bool = true, endpoints: [ProxyEndpoint] = [],
        pac: PACConfiguration = .disabled, autoDiscovery: Bool = false, issue: String? = nil
    ) {
        self.name = name
        self.enabled = enabled
        self.endpoints = endpoints
        self.pac = pac
        self.autoDiscovery = autoDiscovery
        self.issue = issue
    }
}

public struct ProxyEndpoint: Sendable {
    public enum Kind: String, CaseIterable, Sendable { case http = "HTTP", https = "HTTPS", socks = "SOCKS" }
    public let kind: Kind
    public let host: String
    public let port: Int

    public init(kind: Kind, host: String, port: Int) { self.kind = kind; self.host = host; self.port = port }
}

public enum PACConfiguration: Sendable {
    case disabled
    case enabled(String)
}

public protocol ServiceProxyReading: Sendable {
    func read() async throws -> [ServiceProxyConfiguration]
}
