import Foundation

public protocol NetworkDiagnosing: Sendable {
    func diagnose(url: URL) async throws -> NetworkReport
}
