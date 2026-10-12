import Foundation

public protocol HTTPSProbing: Sendable {
    func check(url: URL) async -> DiagnosticFinding
}

public struct SystemHTTPSProbe: HTTPSProbing {
    public init() {}
    public func check(url: URL) async -> DiagnosticFinding {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 12
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        do {
            let (_, response) = try await session.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .init(
                id: "system-https", title: "HTTPS 系统网络路径", level: (200..<400).contains(code) ? .pass : .warning,
                detail: "HTTP \(code)。通过 URLSession 使用系统网络配置，供与直连结果对照。")
        } catch {
            return .init(
                id: "system-https", title: "HTTPS 系统网络路径", level: .unavailable, detail: error.localizedDescription)
        }
    }
}
