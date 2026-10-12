import Foundation

/// 为签名的 SMAppService/XPC 助手预留类型化边界，不接受任意命令字符串。
public enum RepairAction: String, Codable, Sendable {
    case flushDNSCache
}

public struct RepairPlan: Sendable {
    public let suggestions: [String]
    public let proposedActions: [RepairAction]
    public init(suggestions: [String], proposedActions: [RepairAction] = []) {
        self.suggestions = suggestions
        self.proposedActions = proposedActions
    }
}
