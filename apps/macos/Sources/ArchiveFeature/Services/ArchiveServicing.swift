import Foundation

public protocol ArchiveServicing: Sendable {
    /// 进度只描述当前阶段，不将压缩时长估算成百分比；失败或取消不发布目标文件。
    func create(
        _ request: ArchiveRequest,
        progress: @escaping @Sendable (ArchiveProgress) async -> Void
    ) async throws -> ArchiveReceipt
}

extension ArchiveServicing {
    public func create(_ request: ArchiveRequest) async throws -> ArchiveReceipt {
        try await create(request, progress: { _ in })
    }
}
