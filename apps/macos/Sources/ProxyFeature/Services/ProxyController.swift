import Foundation

public struct ProxyVersion: Decodable, Sendable {
    public let version: String
    public let meta: Bool?
}

public protocol ProxyControlling: Sendable {
    func version() async throws -> ProxyVersion
}

public enum ProxyError: LocalizedError {
    case invalidEndpoint, invalidSecret, unexpectedResponse, httpStatus(Int), oversizedResponse
    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint: "控制器地址仅支持 http://127.0.0.1:端口 或 http://[::1]:端口。"
        case .invalidSecret: "Secret 不能包含换行符。"
        case .unexpectedResponse: "控制器未返回有效的 HTTP 响应。"
        case .httpStatus(let code): "控制器返回 HTTP \(code)，请检查端口及 Secret。"
        case .oversizedResponse: "控制器响应超过大小限制。"
        }
    }
}

/// 只读控制器适配器，不负责启动核心、导入订阅或修改系统代理。
public struct MihomoController: ProxyControlling {
    public let endpoint: URL
    private let secret: String

    public init(endpoint: URL, secret: String = "") throws {
        guard let components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false),
            components.scheme == "http", ["127.0.0.1", "::1", "[::1]"].contains(components.host ?? ""),
            let port = components.port, (1...65535).contains(port),
            components.user == nil, components.password == nil, components.query == nil,
            components.fragment == nil, ["", "/"].contains(components.path)
        else { throw ProxyError.invalidEndpoint }
        guard secret.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else {
            throw ProxyError.invalidSecret
        }
        self.endpoint = endpoint
        self.secret = secret
    }

    public func versionRequest() -> URLRequest {
        var request = URLRequest(url: endpoint.appendingPathComponent("version"))
        request.timeoutInterval = 5
        if !secret.isEmpty { request.setValue("Bearer " + secret, forHTTPHeaderField: "Authorization") }
        return request
    }

    public func version() async throws -> ProxyVersion {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.connectionProxyDictionary = [:]
        configuration.timeoutIntervalForResource = 8
        let session = URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: versionRequest())
        guard let http = response as? HTTPURLResponse else { throw ProxyError.unexpectedResponse }
        guard http.statusCode == 200 else { throw ProxyError.httpStatus(http.statusCode) }
        var data = Data()
        for try await byte in bytes {
            guard data.count < 64 * 1024 else { throw ProxyError.oversizedResponse }
            data.append(byte)
        }
        return try JSONDecoder().decode(ProxyVersion.self, from: data)
    }
}

private final class NoRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
