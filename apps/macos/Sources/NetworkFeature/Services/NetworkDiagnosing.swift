import Foundation

public protocol NetworkDiagnosing: Sendable {
    func diagnose(url: URL, externalProbes: Bool) async throws -> NetworkReport
}

extension NetworkDiagnosing {
    public func diagnose(url: URL) async throws -> NetworkReport {
        try await diagnose(url: url, externalProbes: true)
    }
}
