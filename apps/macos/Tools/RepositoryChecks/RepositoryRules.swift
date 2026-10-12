import Foundation

struct TargetInfo {
    let name: String
    let kind: String
    let path: String
    let dependencies: Set<String>
    let excludes: Set<String>
}

enum RepositoryRules {
    /// 目录枚举可能保留 /private 前缀，根 URL 却使用别名；先对两侧采用相同归一化。
    static func repositoryPath(for file: URL, root: URL) -> String? {
        let components = file.resolvingSymlinksInPath().standardizedFileURL.pathComponents
        let rootComponents = root.resolvingSymlinksInPath().standardizedFileURL.pathComponents
        guard components.starts(with: rootComponents), components.count > rootComponents.count else { return nil }
        return components.dropFirst(rootComponents.count).joined(separator: "/")
    }

    static func targets(from data: Data, packagePath: String = "") throws -> [TargetInfo] {
        guard let package = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let targets = package["targets"] as? [[String: Any]]
        else {
            throw CheckError.invalidManifest
        }
        return try targets.map { target in
            guard let name = target["name"] as? String, let kind = target["type"] as? String,
                let dependencies = target["dependencies"] as? [[String: Any]]
            else {
                throw CheckError.invalidManifest
            }
            let names = try dependencies.map { dependency -> String in
                for key in ["byName", "target", "product"] {
                    if let values = dependency[key] as? [Any], let name = values.first as? String { return name }
                }
                throw CheckError.invalidManifest
            }
            let modulePath = target["path"] as? String ?? "\(kind == "test" ? "Tests" : "Sources")/\(name)"
            return TargetInfo(
                name: name, kind: kind,
                path: packagePath.isEmpty ? modulePath : "\(packagePath)/\(modulePath)",
                dependencies: Set(names), excludes: Set(target["exclude"] as? [String] ?? []))
        }
    }

    static func dependencyIssues(_ targets: [TargetInfo]) -> [String] {
        let names = Set(targets.map(\.name))
        return targets.flatMap { target -> [String] in
            let allowed: Set<String>
            switch target.name {
            case "KaiwuCore", "CloudServices", "RepositoryChecks": allowed = []
            case "KaiwuUI": allowed = ["KaiwuCore"]
            case "KaiwuApp":
                allowed = names.filter {
                    $0.hasSuffix("Feature") || ["KaiwuCore", "KaiwuUI", "CloudServices"].contains($0)
                }
            default:
                if target.kind == "test" { return [] }
                guard target.name.hasSuffix("Feature") else { return ["\(target.name)：未声明模块层级，请先更新架构规则。"] }
                allowed = ["KaiwuCore", "KaiwuUI"]
            }
            return target.dependencies.intersection(names).subtracting(allowed).sorted().map {
                "\(target.name)：不允许依赖 \($0)。"
            }
        }
    }

    /// 只检查本仓库采用的单行 import 语法，不替代 Swift 编译器或完整语法分析。
    static func importIssues(source: String, target: TargetInfo, moduleNames: Set<String>) -> [String] {
        let pattern =
            #"(?m)^\s*(?:@\w+(?:\([^\n]*\))?\s+)*(?:(?:public|internal|package|private|fileprivate)\s+)?import\s+(?:(?:struct|class|enum|protocol|func|var|let|typealias)\s+)?(\w+)"#
        let imports = captures(pattern, in: source)
        return imports.compactMap { module in
            if moduleNames.contains(module), !target.dependencies.contains(module) {
                return "\(target.name)：import \(module) 未在 Package.swift 中直接声明依赖。"
            }
            if ["KaiwuCore", "CloudServices"].contains(target.name), ["AppKit", "SwiftUI"].contains(module) {
                return "\(target.name)：领域/云服务层不允许 import \(module)。"
            }
            return nil
        }
    }

    static func markdownIssues(_ markdown: String, file: URL, root: URL) -> [String] {
        var fenced = false
        let prose = markdown.components(separatedBy: .newlines).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") { fenced.toggle(); return false }
            return !fenced
        }.joined(separator: "\n")
        return captures(#"!?\[[^\]]*\]\(([^)]+)\)"#, in: prose).compactMap { raw in
            let link = raw.trimmingCharacters(in: CharacterSet(charactersIn: "<> "))
            if link.hasPrefix("#") || ["https://", "http://", "mailto:"].contains(where: link.hasPrefix) { return nil }
            guard !link.hasPrefix("/"), !link.contains("://") else { return "文档链接必须使用仓库相对路径：\(link)" }
            let path = String(link.split(separator: "#", maxSplits: 1).first ?? "")
            let url = file.deletingLastPathComponent().appendingPathComponent(path.removingPercentEncoding ?? path)
                .standardizedFileURL
            guard url.pathComponents.starts(with: root.standardizedFileURL.pathComponents),
                FileManager.default.fileExists(atPath: url.path)
            else { return "失效或越界的文档链接：\(link)" }
            return nil
        }
    }

    static func textIssues(_ text: String) -> [String] {
        var issues: [String] = []
        if !text.isEmpty && (!text.hasSuffix("\n") || text.hasSuffix("\n\n")) { issues.append("文件必须以恰好一个换行结尾。") }
        if text.utf8.contains(13) { issues.append("文件必须使用 LF 换行。") }
        if text.components(separatedBy: "\n").contains(where: { $0.hasSuffix(" ") || $0.hasSuffix("\t") }) {
            issues.append("存在行尾空白。")
        }
        return issues
    }

    private static func captures(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { preconditionFailure("仓库检查器正则无效") }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }
}

enum CheckError: LocalizedError {
    case invalidManifest
    var errorDescription: String? { "无法解析 swift package dump-package 的输出。" }
}
