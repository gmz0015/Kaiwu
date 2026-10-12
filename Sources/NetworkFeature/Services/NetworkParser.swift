import Foundation

public enum NetworkParser {
    public static func isFakeIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        let numbers = parts.compactMap { Int($0) }
        return numbers.count == 4 && numbers.allSatisfy { (0...255).contains($0) }
            && numbers[0] == 198 && (numbers[1] == 18 || numbers[1] == 19)
    }

    public static func value(_ key: String, in output: String) -> String? {
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == key {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    public static func fakeIPTunnelInterfaces(in output: String) -> [String] {
        var current = ""
        var interfaces: Set<String> = []
        for line in output.components(separatedBy: .newlines) {
            if !line.hasPrefix("\t"), !line.hasPrefix(" "), let name = line.split(separator: ":").first {
                current = String(name)
            }
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            if current.hasPrefix("utun"), fields.count > 1, fields[0] == "inet", isFakeIPv4(String(fields[1])) {
                interfaces.insert(current)
            }
        }
        return interfaces.sorted()
    }

    public static func systemAddresses(in output: String) -> [String] {
        output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2,
                ["ip_address", "ipv6_address"].contains(parts[0].trimmingCharacters(in: .whitespaces))
            else { return nil }
            return parts[1].trimmingCharacters(in: .whitespaces)
        }
    }
}
