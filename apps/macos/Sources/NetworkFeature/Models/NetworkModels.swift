import Foundation

public enum DiagnosticLevel: String, Sendable { case pass, info, warning, failure, unavailable, skipped }

public struct DiagnosticFinding: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let level: DiagnosticLevel
    public let detail: String
    public init(id: String, title: String, level: DiagnosticLevel, detail: String) {
        self.id = id; self.title = title; self.level = level; self.detail = detail
    }
}

public struct NetworkReport: Sendable {
    public let date: Date
    public let findings: [DiagnosticFinding]
    public let repairPlan: RepairPlan
}
