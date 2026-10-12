import Foundation

public enum DiagnosticCategory: String, CaseIterable, Sendable {
    case configuration = "网络配置"
    case resolution = "DNS 解析"
    case connectivity = "连通性"
    case proxies = "代理与 PAC"
}

extension DiagnosticFinding {
    public var category: DiagnosticCategory {
        switch id {
        case "dns", "external-dns": .resolution
        case "direct", "system-https": .connectivity
        case "proxy": .proxies
        default: id.hasPrefix("service-") ? .proxies : .configuration
        }
    }
}

extension DiagnosticLevel {
    public var title: String {
        switch self {
        case .pass: "通过"
        case .info: "信息"
        case .warning: "需留意"
        case .failure: "失败"
        case .unavailable: "未取得结果"
        case .skipped: "未运行"
        }
    }
}
