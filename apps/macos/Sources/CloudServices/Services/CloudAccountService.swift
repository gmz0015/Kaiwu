import CloudKit
import Foundation

public enum CloudAccountState: String, Sendable {
    case disabled = "尚未配置"
    case available = "iCloud 可用"
    case noAccount = "未登录 iCloud"
    case restricted = "iCloud 访问受限"
    case unavailable = "iCloud 暂不可用"
}

public protocol CloudAccountServicing: Sendable {
    func accountState() async throws -> CloudAccountState
}

public struct DisabledCloudAccountService: CloudAccountServicing {
    public init() {}
    public func accountState() async throws -> CloudAccountState { .disabled }
}

/// 仅在 Xcode 中配置真实容器与签名权限后实例化。
public actor CloudKitAccountService: CloudAccountServicing {
    private let container: CKContainer
    public init(containerIdentifier: String) { container = CKContainer(identifier: containerIdentifier) }
    public func accountState() async throws -> CloudAccountState {
        switch try await container.accountStatus() {
        case .available: .available
        case .noAccount: .noAccount
        case .restricted: .restricted
        case .couldNotDetermine, .temporarilyUnavailable: .unavailable
        @unknown default: .unavailable
        }
    }
}
