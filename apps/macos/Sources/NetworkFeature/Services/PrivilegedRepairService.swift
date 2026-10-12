import Foundation

public protocol PrivilegedRepairServicing: Sendable {
    func execute(_ actions: [RepairAction]) async throws
}

public struct UnavailableRepairService: PrivilegedRepairServicing {
    public init() {}
    public func execute(_ actions: [RepairAction]) async throws { throw RepairError.helperNotInstalled }
}

public enum RepairError: LocalizedError {
    case helperNotInstalled
    public var errorDescription: String? { "提权修复助手尚未接入。当前版本仅诊断，不会修改 DNS、路由或代理设置。" }
}
