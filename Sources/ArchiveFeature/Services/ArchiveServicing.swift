import Foundation

public protocol ArchiveServicing: Sendable {
    func create(_ request: ArchiveRequest) async throws -> ArchiveReceipt
}
