import Foundation

/// 白名单摘要不序列化任何命令输出、用户标题、URL、服务名或错误详情。
public enum NetworkReportExport {
    public static func text(_ report: NetworkReport) -> String {
        var lines = [
            "开物 Kaiwu · 网络诊断摘要", "检查时间：" + report.date.formatted(.iso8601),
            "仅包含检查类型与状态。地址、服务名、路径、PAC、原始输出与错误详情均不导出。",
            "单次诊断不能证明所有网络路径正常。", "",
        ]
        let titles = [
            "dns-config": "DNS 配置", "default-route": "默认路由", "public-route": "公网出口路由",
            "interfaces": "TUN / Fake IP 接口", "dns": "系统 DNS", "external-dns": "外部 DNS 对照",
            "direct": "HTTPS 直连", "system-https": "HTTPS 系统路径", "proxy": "系统动态代理",
        ]
        for category in DiagnosticCategory.allCases {
            let findings = report.findings.filter { $0.category == category }
            guard !findings.isEmpty else { continue }
            lines.append(category.rawValue)
            for (index, finding) in findings.enumerated() {
                let title = titles[finding.id] ?? serviceTitle(finding.id) ?? "检查 \(index + 1)"
                lines.append("• \(title)：\(finding.level.title)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
    private static func serviceTitle(_ id: String) -> String? {
        let parts = id.split(separator: "-")
        guard parts.count == 3, parts[0] == "service", let index = Int(parts[1]), (0..<10000).contains(index) else {
            return nil
        }
        let titles = [
            "HTTP": "HTTP 代理", "HTTPS": "HTTPS 代理", "SOCKS": "SOCKS 代理", "PAC": "PAC", "state": "配置",
            "discovery": "自动发现",
        ]
        guard let title = titles[String(parts[2])] else { return nil }
        return "网络服务 \(index + 1) · " + title
    }
}

public actor NetworkReportWriter {
    public init() {}
    public func write(_ text: String, to destination: URL) throws {
        try Task.checkCancellation()
        try text.write(to: destination, atomically: true, encoding: .utf8)
    }
}
