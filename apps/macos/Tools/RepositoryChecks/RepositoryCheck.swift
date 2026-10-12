import Foundation

@main
enum RepositoryCheck {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            print("Usage: repository-check <repository-root> <package-dump.json>")
            exit(2)
        }
        let root = URL(fileURLWithPath: CommandLine.arguments[1]).resolvingSymlinksInPath().standardizedFileURL
        let packagePath = "apps/macos"
        let packageRoot = root.appendingPathComponent(packagePath)
        let manifest = URL(fileURLWithPath: CommandLine.arguments[2])
        let data = try Data(contentsOf: manifest)
        let targets = try RepositoryRules.targets(from: data, packagePath: packagePath)
        let moduleNames = Set(targets.map(\.name))
        var issues = RepositoryRules.dependencyIssues(targets)
        let fm = FileManager.default
        let ignored: Set<String> = [
            ".git", ".build", ".swiftpm", ".worktrees", "dist", "DerivedData", "xcuserdata", "node_modules",
        ]
        let extensions: Set<String> = [
            "swift", "md", "sh", "json", "yml", "yaml", "toml", "xcconfig", "plist", "entitlements", "xcscheme",
        ]
        guard let files = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        else {
            throw CocoaError(.fileReadUnknown)
        }
        for case let file as URL in files {
            let values = try file.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if values.isDirectory == true {
                if ignored.contains(file.lastPathComponent) { files.skipDescendants() }
                continue
            }
            if values.isSymbolicLink == true { continue }
            guard let relative = RepositoryRules.repositoryPath(for: file, root: root) else {
                issues.append("无法将枚举文件定位到仓库内：\(file.lastPathComponent)。")
                continue
            }
            if relative == "\(packagePath)/Configuration/Local.xcconfig" { continue }
            guard
                extensions.contains(file.pathExtension)
                    || ["Makefile", ".swift-format", ".editorconfig", ".gitignore", ".gitattributes"].contains(
                        file.lastPathComponent)
            else { continue }
            let text = try String(contentsOf: file, encoding: .utf8)
            var fileIssues = RepositoryRules.textIssues(text)
            if file.pathExtension == "md" { fileIssues += RepositoryRules.markdownIssues(text, file: file, root: root) }
            if file.pathExtension == "swift", let target = targets.first(where: { relative.hasPrefix($0.path + "/") }) {
                fileIssues += RepositoryRules.importIssues(source: text, target: target, moduleNames: moduleNames)
            }
            issues += fileIssues.map { "\(relative)：\($0)" }
        }
        for target in targets where target.kind != "test" {
            let readme = root.appendingPathComponent(target.path).appendingPathComponent("README.md")
            if !fm.fileExists(atPath: readme.path) { issues.append("\(target.path)：缺少模块 README。"); continue }
            let text = try String(contentsOf: readme, encoding: .utf8)
            for heading in ["## 职责", "## 现状", "## 已完成", "## 下一步", "## 验证"] where !text.contains(heading) {
                issues.append("\(target.path)/README.md：缺少 \(heading)。")
            }
            if !target.excludes.contains("README.md") { issues.append("\(target.name)：Package.swift 未排除模块 README。") }
        }
        issues += try metadataIssues(data: data, root: packageRoot)
        if issues.isEmpty {
            print("仓库检查通过：目录、模块依赖、文档链接与应用元数据。")
        } else {
            issues.sorted().forEach { print("error: " + $0) }
            exit(1)
        }
    }

    private static func metadataIssues(data: Data, root: URL) throws -> [String] {
        let text = try String(contentsOf: root.appendingPathComponent("Configuration/App.xcconfig"), encoding: .utf8)
        let entries = text.split(separator: "\n").filter { !$0.hasPrefix("//") }.compactMap {
            line -> (String, String)? in
            let parts = line.components(separatedBy: " = ")
            return parts.count == 2 ? (parts[0], parts[1]) : nil
        }
        var settings: [String: String] = [:]
        var issues: [String] = []
        for (key, value) in entries {
            if settings.updateValue(value, forKey: key) != nil { issues.append("App.xcconfig：重复配置 \(key)。") }
        }
        for key in [
            "PRODUCT_NAME", "APP_DISPLAY_NAME", "PRODUCT_BUNDLE_IDENTIFIER", "MARKETING_VERSION",
            "CURRENT_PROJECT_VERSION",
            "MACOSX_DEPLOYMENT_TARGET",
        ] {
            let pattern = key == "APP_DISPLAY_NAME" ? #"^[\p{L}\p{N} .-]+$"# : "^[A-Za-z0-9.-]+$"
            guard let value = settings[key], value.range(of: pattern, options: .regularExpression) != nil
            else {
                issues.append("App.xcconfig：\(key) 必须是非空的简单字面量。")
                continue
            }
        }
        let package = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let platforms = package?["platforms"] as? [[String: Any]]
        let minimum = platforms?.first { $0["platformName"] as? String == "macos" }?["version"] as? String
        if minimum != settings["MACOSX_DEPLOYMENT_TARGET"] {
            issues.append("Package.swift 与 App.xcconfig 的最低 macOS 版本不一致。")
        }
        let products = package?["products"] as? [[String: Any]] ?? []
        if !products.contains(where: {
            $0["name"] as? String == settings["PRODUCT_NAME"] && $0["targets"] as? [String] == ["KaiwuApp"]
        }) {
            issues.append("Package.swift 缺少 App.xcconfig 对应的应用产品。")
        }
        let plist = try Data(contentsOf: root.appendingPathComponent("Configuration/Info.plist"))
        let info = try PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: Any]
        for (key, setting) in [
            "CFBundleExecutable": "PRODUCT_NAME", "CFBundleName": "APP_DISPLAY_NAME",
            "CFBundleDisplayName": "APP_DISPLAY_NAME", "CFBundleIdentifier": "PRODUCT_BUNDLE_IDENTIFIER",
            "CFBundleShortVersionString": "MARKETING_VERSION", "CFBundleVersion": "CURRENT_PROJECT_VERSION",
            "LSMinimumSystemVersion": "MACOSX_DEPLOYMENT_TARGET",
        ] {
            if info?[key] as? String != "$(\(setting))" { issues.append("Info.plist 的 \(key) 必须引用 $(\(setting))。") }
        }
        return issues
    }
}
